terraform {
    required_providers {
        google-beta = {
        source  = "hashicorp/google-beta"
        version = "~>4"
        }
    }
}

provider "google" {
    project     = var.project_id
    region      = var.region
}

provider "google-beta" {
    project     = var.project_id
    region      = var.region
}