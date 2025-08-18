################################################################################
# EKS Cluster Outputs
################################################################################
output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

################################################################################
# ACM Certificate Outputs
################################################################################
output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = module.acm.certificate_arn
}

output "prometheus_url" {
  description = "URL for Prometheus dashboard"
  value       = "https://${module.acm.prometheus_fqdn}"
}

output "grafana_url" {
  description = "URL for Grafana dashboard"
  value       = "https://${module.acm.grafana_fqdn}"
}

################################################################################
# Load Balancer Outputs
################################################################################
output "nginx_ingress_load_balancer_hostname" {
  description = "Hostname of the nginx ingress load balancer"
  value       = data.kubernetes_service.nginx_ingress_controller.status.0.load_balancer.0.ingress.0.hostname
}

################################################################################
# Domain Configuration
################################################################################
output "domain_name" {
  description = "Primary domain name"
  value       = var.domain_config.domain_name
}

output "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  value       = module.acm.hosted_zone_id
}