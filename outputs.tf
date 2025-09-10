################################################################################
# EKS Cluster Outputs
################################################################################
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

/*
################################################################################
# Monitoring Outputs
################################################################################
output "prometheus_service_info" {
  description = "Prometheus service information"
  value = {
    namespace    = kubernetes_namespace.monitoring.metadata[0].name
    service_name = "prometheus-kube-prometheus-prometheus"
  }
}

output "grafana_service_info" {
  description = "Grafana service information"
  value = {
    namespace      = kubernetes_namespace.monitoring.metadata[0].name
    service_name   = "prometheus-grafana"
    admin_password = "admin123"
  }
}

output "monitoring_access_commands" {
  description = "Commands to access monitoring services"
  value = {
    prometheus_url          = "http://prometheus.chinmayto.com"
    grafana_url             = "http://grafana.chinmayto.com"
    prometheus_port_forward = "kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
    grafana_port_forward    = "kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
    get_nginx_loadbalancer  = "kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
    check_ingress_status    = "kubectl get ingress -n monitoring"
  }
}
*/