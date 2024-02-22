variable "project_id" {
  description = "ID of the project in which to create resources"
  type        = string
  default     = "cloud-csye-6225"
}

variable "vpc_name" {
  description = "The name of the VPC network"
  type        = list(string)
  default     = ["cloud-vpc"]
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
  default     = "n2-standard-2"
}

variable "image_name" {
    description = "The name of the image to use for the VM"
    type        = string
    default     = "c0-deeplearning-common-cpu-v20230925-debian-10"
}

