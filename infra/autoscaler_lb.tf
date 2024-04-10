resource "google_compute_region_instance_template" "webapp_instance_template" {
  name = "webapp-instance-template"
  description = "This is the webapp instance template"

  machine_type = var.machine_type
  can_ip_forward = false

  disk {
    source_image = var.image_name
    auto_delete = true
    type = "pd-balanced"
    disk_size_gb = 50

    disk_encryption_key {
      kms_key_self_link = google_kms_crypto_key.vm_instance_key.id
    }
  }

  network_interface {
    network = google_compute_network.vpc_name.self_link
    subnetwork = google_compute_subnetwork.webapp.self_link
    access_config {}
  }

  service_account {
    email = google_service_account.service_account.email
    scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/pubsub",
      "https://www.googleapis.com/auth/cloudkms",
    ]
  }

  tags = ["webapp"]
  depends_on = [google_kms_crypto_key.vm_instance_key, google_service_account.service_account, google_kms_key_ring.key_ring]

  metadata_startup_script = local.startup_script
}

resource "google_compute_region_instance_group_manager" "webapp_instance_group_manager" {
  name = "webapp-instance-manager"
  base_instance_name = "webapp-instance"
  region = var.region

  distribution_policy_zones = ["us-east1-c", "us-east1-d"]

  version {
    instance_template = google_compute_region_instance_template.webapp_instance_template.self_link
  }
  named_port {
    name = "port-name-webapp"
    port = 8080
  }
  auto_healing_policies {
    health_check      = google_compute_region_health_check.webapp_health_check.id
    initial_delay_sec = 300
  }
}

resource "google_compute_region_health_check" "webapp_health_check" {
  name = "webapp-health-check"
  description = "Health check via http"

  timeout_sec = 10
  check_interval_sec = 20

  http_health_check {
    request_path = "/healthz"
    port = "8080"
  }

  log_config {
    enable = true
  }
}

resource "google_compute_region_autoscaler" "webapp_autoscaler" {
  name = "webapp-autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.webapp_instance_group_manager.self_link

  autoscaling_policy {
    max_replicas = 3
    min_replicas = 1
    cooldown_period = 180

    cpu_utilization {
      target = 0.05
    }
  }
}

############################## Cloud DNS setup ##############################
resource "google_dns_record_set" "a" {
  name         = var.domain_name
  managed_zone = var.hosted_zone_name
  type         = "A"
  ttl          = 60

  rrdatas = [module.gce_lb_http.external_ip]
}

module "gce_lb_http" {
  source            = "GoogleCloudPlatform/lb-http/google"
  version           = "~> 9.0"
  project           = var.project_id
  name              = "group-http-lb"
  ssl = true
  managed_ssl_certificate_domains = ["divyashree.me"]
  http_forward = false
  backends = {
    default = {
      port                            = 8080
      protocol                        = "HTTP"
      port_name                       = "port-name-webapp"
      timeout_sec                     = 120
      enable_cdn                      = false

      health_check = {
        request_path        = "/healthz"
        port                = 8080
      }

      log_config = {
        enable = true
        sample_rate = 1.0
      }

      groups = [
        {
          group     = google_compute_region_instance_group_manager.webapp_instance_group_manager.instance_group
        },
      ]

      iap_config = {
        enable               = false
      }
    }
  }
}


















