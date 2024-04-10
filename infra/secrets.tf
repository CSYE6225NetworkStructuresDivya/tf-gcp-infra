#KMS Ring
resource "google_secret_manager_secret" "kms_key_ring" {
    secret_id = "kmskeyring"
    replication {
      auto {}
    }
}

resource "google_secret_manager_secret_version" "kms_key_ring" {
    secret      = google_secret_manager_secret.kms_key_ring.id
    secret_data = google_kms_key_ring.key_ring.name
}

#KMS vm instance key
resource "google_secret_manager_secret" "vm_kms_crypto_key" {
    secret_id = "vmkmscryptokey"
    replication {
      auto {}
    }
}

resource "google_secret_manager_secret_version" "vm_kms_crypto_key" {
    secret      = google_secret_manager_secret.vm_kms_crypto_key.id
    secret_data = google_kms_crypto_key.vm_instance_key.name
}

# Startup script secret
resource "google_secret_manager_secret" "metadata_startup_script" {
    secret_id = "metadatastartupscript"
    replication {
      auto {}
    }
}

resource "google_secret_manager_secret_version" "metadata_startup_script" {
    secret      = google_secret_manager_secret.metadata_startup_script.id
    secret_data = local.startup_script
}

# Secret instance manager name
resource "google_secret_manager_secret" "instance_manager_name" {
  secret_id = "instancemanagername"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "instance_manager_name" {
  secret      = google_secret_manager_secret.instance_manager_name.id
  secret_data = google_compute_region_instance_group_manager.webapp_instance_group_manager.name
}

# Secret datasource url
resource "google_secret_manager_secret" "datasource_url" {
    secret_id = "datasourceurl"
    replication {
      auto {}
    }
}

resource "google_secret_manager_secret_version" "datasource_url" {
    secret      = google_secret_manager_secret.datasource_url.id
    secret_data = "jdbc:mysql://${google_sql_database_instance.mysql_instance.private_ip_address}:3306/${google_sql_database.mysql_db.name}"
}

# secret db user
resource "google_secret_manager_secret" "db_user" {
    secret_id = "dbuser"
    replication {
      auto {}
    }
}

resource "google_secret_manager_secret_version" "db_user" {
    secret      = google_secret_manager_secret.db_user.id
    secret_data = google_sql_user.mysql_user.name
}

# secret db password
resource "google_secret_manager_secret" "db_password" {
    secret_id = "dbpassword"
    replication {
      auto {}
    }
}

resource "google_secret_manager_secret_version" "db_password" {
    secret      = google_secret_manager_secret.db_password.id
    secret_data = google_sql_user.mysql_user.password
}

# pub-sub topic name
resource "google_secret_manager_secret" "pub_sub_topic_name" {
    secret_id = "pubsubtopicname"
    replication {
      auto {}
    }
}

resource "google_secret_manager_secret_version" "pub_sub_topic_name" {
    secret      = google_secret_manager_secret.pub_sub_topic_name.id
    secret_data = google_pubsub_topic.verify_email_topic.name
}












