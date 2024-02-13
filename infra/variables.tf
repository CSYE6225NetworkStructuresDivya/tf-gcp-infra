variable "project_id" {
  description = "ID of the project in which to create resources"
  type        = string
  default     = "quiet-being-408814"
}

variable "credentials_file" {
  description = "Path to the service account key file"
  type        = string
  default     = "../quiet-being-408814-43805bdcb2a7.json"
}

variable "region" {
  description = "The region in which to create resources"
  type        = string
  default     = "us-east1"
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

