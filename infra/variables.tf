variable "project_id" {
  description = "ID of the project in which to create resources"
  type        = string
  default     = "cloud-csye-6225"
}

variable "vpc_name" {
  description = "The name of the VPC network"
  type        =  string
  default     = "cloud-vpc"
}

variable "region" {
  description = "The region in which to create resources"
  type        = string
  default     = "us-east1"
}

variable "routing_mode" {
  description = "The network routing mode (default is REGIONAL)"
  type        = string
  default     = "REGIONAL"
}

variable "zone" {
  description = "The zone in which to create resources"
  type        = string
  default     = "us-east1-b"
}

variable "webapp_ip_cidr_range" {
  description = "The IP CIDR range for the webapp subnet"
  type        = string
  default     = "10.1.0.0/24"
}

variable "db_ip_cidr_range" {
  description = "The IP CIDR range for the db subnet"
  type        = string
  default     = "10.2.0.0/24"
}

variable "private_service_ip" {
    description = "The IP CIDR range for the google private services"
    type        = string
    default     = "10.3.0.0"
}

variable "webapp_destination_ip_range" {
  description = "The destination IP range for the webapp route"
  type        = string
  default     = "0.0.0.0/0"
}

variable "webapp_route_next_hop_gateway" {
  description = "The next hop gateway for the webapp route"
  type        = string
  default     = "default-internet-gateway"
}

variable "machine_type" {
  description = "The machine type to use for the VM"
  type        = string
  default     = "e2-medium"
}

variable "image_name" {
    description = "The name of the image to use for the VM"
    type        = string
    default     = "packer-1709133046"
}

variable "cloudsql_configuration" {
    description = "The configurations for the Cloud SQL instance"
    type = object({
        delete_protection = bool
        availability_type = string
        disk_type = string
        disk_size = number
        ipv4_enabled = bool
        tier = string
    })
    default = {
        delete_protection = false
        availability_type = "REGIONAL"
        disk_type = "PD_SSD"
        disk_size = 100
        ipv4_enabled = false
        tier = "db-custom-1-3840"
    }
}

variable "hosted_zone_name" {
    description = "The name of the DNS zone"
    type        = string
    default     = "csye6225assignment"
}

variable "domain_name" {
    description = "The name of the host"
    type        = string
    default     = "divyashree.me."
}

variable "key_ring_name" {
    description = "The name of the key ring"
    type        = string
    default     = "kms-key-ring-test6"
}

variable "vm_instance_key_name" {
    description = "The name of the key to use for the VM instance"
    type        = string
    default     = "vm-instance-key-test6"
}

variable "cloud_sql_key_name" {
    description = "The name of the key to use for the Cloud SQL instance"
    type        = string
    default     = "cloud-sql-key-test6"
}

variable "storage_bucket_key_name" {
  description = "The name of the key to use for the storage bucket"
  type        = string
  default     = "storage-bucket-key-test6"
}

variable "key_rotation_period" {
    description = "The rotation period for the key"
    type        = string
    default     = "2592000s" #(30 days)
}

variable "key_destroy_scheduled_duration" {
    description = "The scheduled duration for the key to be destroyed"
    type        = string
    default     = "86400s"
}