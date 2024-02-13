# Purpose: Create a VPC for the project
resource "google_compute_network" "cloud-assignment-vpc" {
  name = "cloud-assignment-vpc"
  auto_create_subnetworks = false
}

# Purpose: Create a webapp subnet for the VPC
resource "google_compute_subnetwork" "webapp" {
  name          = "webapp"
  ip_cidr_range = var.webapp_ip_cidr_range
  region        = var.region
  network       = google_compute_network.cloud-assignment-vpc.self_link
}

# Purpose: Create a db subnet for the VPC
resource "google_compute_subnetwork" "db" {
  name          = "db"
  ip_cidr_range = var.db_ip_cidr_range
  region        = var.region
  network       = google_compute_network.cloud-assignment-vpc.self_link
}

# Define routes
resource "google_compute_route" "webapp_route" {
    name                  = "webapp-route"
    network               = google_compute_network.cloud-assignment-vpc.self_link
    dest_range            = var.webapp_destination_ip_range
    next_hop_gateway      = var.webapp_route_next_hop_gateway
}