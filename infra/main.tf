# Purpose: Create a VPC for the project
resource "google_compute_network" "vpc_name" {
  name = var.vpc_name
  auto_create_subnetworks = false
  routing_mode = var.routing_mode
  delete_default_routes_on_create = true
}

# Purpose: Create a webapp subnet for the VPC
resource "google_compute_subnetwork" "webapp" {
  name          = "webapp"
  ip_cidr_range = var.webapp_ip_cidr_range
  region        = var.region
  network       = google_compute_network.vpc_name.self_link
}

# Purpose: Create a db subnet for the VPC
resource "google_compute_subnetwork" "db" {
  name          = "db"
  ip_cidr_range = var.db_ip_cidr_range
  region        = var.region
  network       = google_compute_network.vpc_name.self_link
  private_ip_google_access = true
}

# Define routes
resource "google_compute_route" "webapp_route" {
  name                  = "webapp-route"
  network               = google_compute_network.vpc_name.self_link
  dest_range            = var.webapp_destination_ip_range
  next_hop_gateway      = var.webapp_route_next_hop_gateway
}

# Create firewall rules
resource "google_compute_firewall" "allow_webapp_traffic" {
  name        = "allow-webapp-traffic"
  network     = google_compute_network.vpc_name.self_link
  allow {
    protocol = "tcp"
    ports    = ["8080", "22", "443"]
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags = ["webapp"]
}

#resource "google_compute_firewall" "deny_ssh" {
#
#  name        = "deny-ssh"
#  network     = google_compute_network.vpc_name.self_link
#  deny {
#    protocol = "tcp"
#    ports    = ["22"]
#  }
#  source_ranges = ["0.0.0.0/0"]
#}

resource "google_compute_firewall" "webapp_to_db" {
  name    = "webapp-to-db-traffic"
  network = google_compute_network.vpc_name.self_link
  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }
  source_tags = [google_tags_tag_key.webapp_tag_key.short_name]
  destination_ranges = ["${google_compute_global_address.private_services_ips.address}/${google_compute_global_address.private_services_ips.prefix_length}"]
  depends_on = [google_compute_global_address.private_services_ips]
}


# reserve an IP range for google private service access
resource "google_compute_global_address" "private_services_ips" {
  provider      = google-beta
  project       = var.project_id
  name          = "google-managed-services"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_name.self_link
}

# Set up VPC peering with Google's internal VPC that hosts Cloud SQL instances
resource "google_service_networking_connection" "private_vpc_connection" {
  provider                = google-beta
  network                 = google_compute_network.vpc_name.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_services_ips.name]
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

#Bind the service account to pubsub publisher role
resource "google_project_iam_binding" "pubsub_publisher_role" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${google_service_account.service_account.email}"]
}

#Bind the service account to cloudkms encrypter/decrypter role
resource "google_project_iam_binding" "cloudkms_encrypter_decrypter_role" {
  project = var.project_id
  role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members = ["serviceAccount:${google_service_account.service_account.email}"]
}

############################## Cloud SQL setup ##############################

resource "google_sql_database_instance" "mysql_instance" {
  name = "mysql-${random_string.random_string.result}"
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
      private_network = google_compute_network.vpc_name.self_link
    }
    backup_configuration {
      binary_log_enabled = true
      enabled = true
    }
  }
  depends_on = [google_compute_subnetwork.db, google_service_networking_connection.private_vpc_connection]
  encryption_key_name = google_kms_crypto_key.cloud_sql_key.id
}

resource "google_sql_database" "mysql_db" {
  name = "webapp"
  instance = google_sql_database_instance.mysql_instance.name
  charset = "utf8"
  collation = "utf8_general_ci"
}

resource "random_password" "password" {
  length           = 8
  special          = false
  upper            = true
  lower            = true
}

resource "random_string" "random_string" {
  length           = 6
  special          = false
  numeric           = false
  upper = false
}

resource "google_sql_user" "mysql_user" {
  name = "webapp"
  instance = google_sql_database_instance.mysql_instance.name
  password = random_password.password.result
  depends_on = [google_sql_database.mysql_db]
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

resource "google_pubsub_topic" "verify_email_topic" {
  name = "verify_email"
}

resource "google_storage_bucket" "serverless_storage_bucket" {
  name     = "serverless-function-bucket"
  location = var.region
  force_destroy = true
  encryption {
    default_kms_key_name = google_kms_crypto_key.storage_bucket_key.id
  }
  depends_on = [google_kms_crypto_key_iam_binding.storage_bucket_key_iam_binding]
}

resource "google_storage_bucket_object" "serverless_zip_object" {
  name   = "serverless-function-bucket-object"
  bucket = google_storage_bucket.serverless_storage_bucket.name
  source = "serverless.zip"

  depends_on = [google_storage_bucket.serverless_storage_bucket]
}

resource "google_cloudfunctions2_function" "send_email" {
    name = "verify_email"
    location = var.region
    description = "Send email to verify email address"
    build_config {
      runtime     = "java17"
      entry_point = "cloudfunction.PubSubFunction"

      source {
        storage_source {
          bucket = google_storage_bucket.serverless_storage_bucket.name
          object = google_storage_bucket_object.serverless_zip_object.name
        }
      }
    }
    service_config {
      max_instance_count  = 1
      available_memory    = "256M"
      timeout_seconds     = 60
      vpc_connector = google_vpc_access_connector.connector.self_link
      environment_variables = {
        INSTANCE_HOST = google_sql_database_instance.mysql_instance.private_ip_address
        DB_NAME = google_sql_database.mysql_db.name
        DB_PORT = "3306"
        DB_USER = google_sql_user.mysql_user.name
        DB_PASS = google_sql_user.mysql_user.password
      }
    }

    event_trigger {
      event_type = "google.cloud.pubsub.topic.v1.messagePublished"
      pubsub_topic = google_pubsub_topic.verify_email_topic.id
      retry_policy = "RETRY_POLICY_RETRY"
      service_account_email = google_service_account.pubsub_service_account.email
    }
}

resource "google_vpc_access_connector" "connector" {
  name = "vpc-connector"
  ip_cidr_range = "10.8.0.0/28"
  network = google_compute_network.vpc_name.self_link
}

resource "google_service_account" "pubsub_service_account" {
  account_id = "pub-sub-sa"
  display_name = "Service account for cloud functions"
}

#Bind the service account to pubsub publisher role
resource "google_project_iam_binding" "cloud_run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  members = ["serviceAccount:${google_service_account.pubsub_service_account.email}"]
}

#Bind the service account to pubsub publisher role
resource "google_project_iam_binding" "token_creator" {
  project = var.project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  members = ["serviceAccount:${google_service_account.pubsub_service_account.email}"]
}

locals {
  # Note: change the spring properties values to mirror the values in your app
  startup_script = <<-EOF
#!/bin/bash
if [ ! -f "/opt/csye6225/application.properties" ]; then
{
  echo "spring.jpa.hibernate.ddl-auto=update"
  echo "spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver"
  echo "spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.MySQL8Dialect"
  echo "spring.datasource.type=org.springframework.jdbc.datasource.SimpleDriverDataSource"
  echo "spring.datasource.hikari.connection-timeout=2000"
  echo "spring.datasource.url=jdbc:mysql://${google_sql_database_instance.mysql_instance.private_ip_address}:3306/${google_sql_database.mysql_db.name}"
  echo "spring.datasource.username=${google_sql_user.mysql_user.name}"
  echo "spring.datasource.password=${google_sql_user.mysql_user.password}"
  echo "gcloud_pubsub_topic_id=${google_pubsub_topic.verify_email_topic.name}"
} >> /opt/csye6225/application.properties
sudo chown csye6225:csye6225 /opt/csye6225/application.properties
sudo chmod 660 /opt/csye6225/application.properties
touch /tmp/metadata-test.txt
fi
EOF
}
