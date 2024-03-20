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
  private_ip_google_access = true
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

resource "google_compute_firewall" "webapp_to_db" {
  for_each = google_compute_network.vpc_name

  name    = "webapp-to-db-traffic-${each.key}"
  network = each.value.self_link
  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }
  source_tags = [google_tags_tag_key.webapp_tag_key.short_name]
  destination_ranges = ["${google_compute_global_address.private_services_ips[each.key].address}/${google_compute_global_address.private_services_ips[each.key].prefix_length}"]
  depends_on = [google_compute_global_address.private_services_ips]
}


# reserve an IP range for google private service access
resource "google_compute_global_address" "private_services_ips" {
  for_each = google_compute_network.vpc_name
  provider      = google-beta
  project = var.project_id
  name          = "google-managed-services-${each.key}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_name[each.key].self_link
}

# Set up VPC peering with Google's internal VPC that hosts Cloud SQL instances
resource "google_service_networking_connection" "private_vpc_connection" {
  for_each = google_compute_network.vpc_name
  provider                = google-beta
  network                 = google_compute_network.vpc_name[each.key].self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_services_ips[each.key].name]
}

############################## Compute engine ##############################

# Create compute engine instance
resource "google_compute_instance" "web_instance" {
  for_each = {
    for index, name in var.vpc_name : index  => name
  }

  name         = "webapp-instance-${each.value}"
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
    subnetwork = google_compute_subnetwork.webapp[each.value].self_link
    network = google_compute_network.vpc_name[each.value].self_link
    access_config {}
  }
  metadata_startup_script = local.startup_scripts[each.key]

  service_account {
    email  = google_service_account.service_account.email
    scopes = ["logging-write", "monitoring"]
  }
}

############################# Create Service Account ##############################
resource "google_service_account" "service_account" {
    account_id   = "logging-monitoring-sa"
    display_name = "Observability Service Account"
}

# Bind the service account to Logging Admin role
resource "google_project_iam_binding" "logging_admin_role"  {
  project = var.project_id
  role    = "roles/logging.admin"
  members = ["serviceAccount:${google_service_account.service_account.email}"]
}

# Bind the service account to Monitoring Metric Writer role
resource "google_project_iam_binding" "monitoring_metric_writer_role" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  members = ["serviceAccount:${google_service_account.service_account.email}"]
}

############################## Cloud DNS setup ##############################
resource "google_dns_record_set" "a" {
  for_each = {
    for index, name in var.vpc_name : index  => name
  }
  name         = var.domain_name
  managed_zone = var.hosted_zone_name
  type         = "A"
  ttl          = 60

  rrdatas = flatten([
    for instance in google_compute_instance.web_instance : [
      instance.network_interface.0.access_config.0.nat_ip
    ]
  ])
}

############################## Cloud SQL setup ##############################

resource "google_sql_database_instance" "mysql_instance" {
  for_each = google_compute_network.vpc_name
  name = "mysql-${each.key}-${random_string.random_string.result}"
  database_version = "MYSQL_8_0_31"
  region = var.region
  deletion_protection = var.cloudsql_configuration.delete_protection
  settings {
    tier = var.cloudsql_configuration.tier
    availability_type = var.cloudsql_configuration.availability_type
    disk_type = var.cloudsql_configuration.disk_type
    disk_size = var.cloudsql_configuration.disk_size
    ip_configuration {
      ipv4_enabled = var.cloudsql_configuration.ipv4_enabled
      private_network = google_compute_network.vpc_name[each.key].self_link
    }
    backup_configuration {
      binary_log_enabled = true
      enabled = true
    }
  }
  depends_on = [google_compute_subnetwork.db, google_service_networking_connection.private_vpc_connection]
}

resource "google_sql_database" "mysql_db" {
  for_each = google_compute_network.vpc_name
  name = "webapp"
  instance = google_sql_database_instance.mysql_instance[each.key].name
  charset = "utf8"
  collation = "utf8_general_ci"
}

resource "random_password" "password" {
  length           = 8
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_string" "random_string" {
  length           = 6
  special          = false
  numeric           = false
  upper = false
}

resource "google_sql_user" "mysql_user" {
  for_each = google_compute_network.vpc_name
  name = "webapp"
  instance = google_sql_database_instance.mysql_instance[each.key].name
  password = random_password.password.result
  depends_on = [google_sql_database.mysql_db]
}

output "db_private_ip" {
  value = {
    for instance_key, instance in google_sql_database_instance.mysql_instance :
    instance_key => instance.private_ip_address
  }
}

resource "google_tags_tag_key" "webapp_tag_key" {
  parent = "projects/${var.project_id}"
  short_name = "webapp"
  description = "tag for csye-6225 webapp instances"
}

resource "google_tags_tag_value" "webapp_tag_value" {
  parent = "tagKeys/${google_tags_tag_key.webapp_tag_key.name}"
  short_name = "csye-6225-webapp"
  description = "Value for the csye-6225 webapp tag"
}


locals {
  # Note: change the spring properties values to mirror the values in your app
  startup_scripts = [
    for instance_key, _ in google_sql_database_instance.mysql_instance : <<-EOF
#!/bin/bash
if [ ! -f "/opt/csye6225/application.properties" ]; then
{
  echo "spring.jpa.hibernate.ddl-auto=update"
  echo "spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver"
  echo "spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.MySQL8Dialect"
  echo "spring.datasource.type=org.springframework.jdbc.datasource.SimpleDriverDataSource"
  echo "spring.datasource.hikari.connection-timeout=2000"
  echo "spring.datasource.url=jdbc:mysql://${google_sql_database_instance.mysql_instance[instance_key].private_ip_address}:3306/${google_sql_database.mysql_db[instance_key].name}"
  echo "spring.datasource.username=${google_sql_user.mysql_user[instance_key].name}"
  echo "spring.datasource.password=${google_sql_user.mysql_user[instance_key].password}"
} >> /opt/csye6225/application.properties
sudo chown csye6225:csye6225 /opt/csye6225/application.properties
sudo chmod 660 /opt/csye6225/application.properties
touch /tmp/metadata-test.txt
fi
EOF
  ]
}
