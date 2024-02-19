# Purpose: Create a VPC for the project
resource "google_compute_network" "vpc_name" {
  for_each = {
    for index, name in var.vpc_name : name => index
  }
  name = each.key
  auto_create_subnetworks = false
  routing_mode = "REGIONAL"
  delete_default_routes_on_create = true
}

# Purpose: Create a webapp subnet for the VPC
resource "google_compute_subnetwork" "webapp" {
  for_each = google_compute_network.vpc_name
  name          = "${each.key}-webapp"
  ip_cidr_range = var.webapp_ip_cidr_range
  region        = var.regio
  network       = each.value.self_link
}

# Purpose: Create a db subnet for the VPC
resource "google_compute_subnetwork" "db" {
  for_each = google_compute_network.vpc_name
  name          = "${each.key}-db"
  ip_cidr_range = var.db_ip_cidr_range
  region        = var.region
  network       = each.value.self_link
}

# Define routes
resource "google_compute_route" "webapp_route" {
    for_each = google_compute_network.vpc_name
    name                  = "${each.key}-webapp-route"
    network               = each.value.self_link
    dest_range            = var.webapp_destination_ip_range
    next_hop_gateway      = var.webapp_route_next_hop_gateway
}
