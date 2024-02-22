# Purpose: Create a VPC for the project
resource "google_compute_network" "vpc_name" {
  for_each = {
    for index, name in var.vpc_name : name => index
  }
  name = each.key
  auto_create_subnetworks = false
  routing_mode = var.routing_mode
  delete_default_routes_on_create = true
}

# Purpose: Create a webapp subnet for the VPC
resource "google_compute_subnetwork" "webapp" {
  for_each = google_compute_network.vpc_name
  name          = "${each.key}-webapp"
  ip_cidr_range = var.webapp_ip_cidr_range
  region        = var.region
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

# Create firewall rules
resource "google_compute_firewall" "allow_webapp_traffic" {
  for_each = google_compute_network.vpc_name

  name        = "allow-webapp-traffic-${each.key}"
  network     = each.value.self_link
  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "deny_ssh" {
  for_each = google_compute_network.vpc_name

  name        = "deny-ssh-${each.key}"
  network     = each.value.self_link
  deny {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

# Create compute engine instance
resource "google_compute_instance" "web_instance" {
  for_each = google_compute_network.vpc_name

  name         = "webapp-instance-${each.key}"
  machine_type = var.machine_type
  zone         = var.zone
  boot_disk {
    initialize_params {
        image = var.image_name
        type = "pd-balanced"
        size  = "100"
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.webapp[each.key].self_link
    network = google_compute_network.vpc_name[each.key].self_link
    access_config {}
  }
}