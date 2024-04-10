# SQL service agent identity
resource "google_project_service_identity" "gcp_sa_cloud_sql" {
  provider = google-beta
  service  = "sqladmin.googleapis.com"
}

#Create a key ring
resource "google_kms_key_ring" "key_ring" {
  location = var.region
  name     = var.key_ring_name
}

####################  Create Customer-Managed Encryption Keys (CMEK)  ####################
#Vm instances
resource "google_kms_crypto_key" "vm_instance_key" {
  name     = var.vm_instance_key_name
  key_ring = google_kms_key_ring.key_ring.id
  rotation_period = var.key_rotation_period
  destroy_scheduled_duration = var.key_destroy_scheduled_duration
  lifecycle {
    prevent_destroy = false
  }
}

# Cloud SQL
resource "google_kms_crypto_key" "cloud_sql_key" {
  name     = var.cloud_sql_key_name
  key_ring = google_kms_key_ring.key_ring.id
  rotation_period = var.key_rotation_period
  destroy_scheduled_duration = var.key_destroy_scheduled_duration
  lifecycle {
    prevent_destroy = false
  }
}

# Storage bucket key
resource "google_kms_crypto_key" "storage_bucket_key" {
  name     = var.storage_bucket_key_name
  key_ring = google_kms_key_ring.key_ring.id
  rotation_period = var.key_rotation_period
  destroy_scheduled_duration = var.key_destroy_scheduled_duration
  lifecycle {
    prevent_destroy = false
  }
}

####################  Create CMEK IAM role bindings  ####################
data "google_storage_project_service_account" "gcs_service_account" {
}

resource "google_kms_crypto_key_iam_binding" "storage_bucket_key_iam_binding" {
  crypto_key_id = google_kms_crypto_key.storage_bucket_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members       = ["serviceAccount:${data.google_storage_project_service_account.gcs_service_account.email_address}"]
}

# Cloud SQL
resource "google_kms_crypto_key_iam_binding" "cloud_sql_key_iam_binding" {
  provider      = google-beta
  crypto_key_id = google_kms_crypto_key.cloud_sql_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:${google_project_service_identity.gcp_sa_cloud_sql.email}",
  ]
}

data "google_project" "project" {}

locals {
  compute_engine_service_agent_email = "service-${data.google_project.project.number}@compute-system.iam.gserviceaccount.com"
}

#Vm instances
resource "google_kms_crypto_key_iam_binding" "vm_instance_key_iam_binding" {
  crypto_key_id = google_kms_crypto_key.vm_instance_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members       = ["serviceAccount:${local.compute_engine_service_agent_email}"]
}

