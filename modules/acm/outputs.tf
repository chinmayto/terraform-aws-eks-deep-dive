output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = aws_acm_certificate_validation.main.certificate_arn
}

output "certificate_domain_name" {
  description = "Domain name of the certificate"
  value       = aws_acm_certificate.main.domain_name
}

output "certificate_status" {
  description = "Status of the certificate"
  value       = aws_acm_certificate.main.status
}

output "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  value       = data.aws_route53_zone.main.zone_id
}

output "prometheus_fqdn" {
  description = "Fully qualified domain name for Prometheus"
  value       = aws_route53_record.prometheus.fqdn
}

output "grafana_fqdn" {
  description = "Fully qualified domain name for Grafana"
  value       = aws_route53_record.grafana.fqdn
}