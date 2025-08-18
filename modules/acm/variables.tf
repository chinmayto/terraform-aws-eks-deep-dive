variable "domain_name" {
  description = "The primary domain name for the ACM certificate"
  type        = string
}

variable "subject_alternative_names" {
  description = "List of subject alternative names for the ACM certificate"
  type        = list(string)
  default     = []
}

variable "prometheus_subdomain" {
  description = "Subdomain for Prometheus (e.g., prometheus.chinmayto.com)"
  type        = string
}

variable "grafana_subdomain" {
  description = "Subdomain for Grafana (e.g., grafana.chinmayto.com)"
  type        = string
}

variable "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  type        = string
}

variable "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "naming_prefix" {
  description = "Prefix for resource names"
  type        = string
}