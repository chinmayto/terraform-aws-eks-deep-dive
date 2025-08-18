################################################################################
# Create VPC and components
################################################################################

module "vpc" {
  source          = "./modules/vpc"
  networking      = var.networking
  security_groups = var.security_groups
  common_tags     = local.common_tags
  naming_prefix   = local.naming_prefix
  cluster_name    = var.cluster_config.name
}


################################################################################
# Create EKS Cluster and Node Groups
################################################################################

module "eks" {
  source             = "./modules/eks"
  public_subnets_id  = module.vpc.public_subnets_id
  private_subnets_id = module.vpc.private_subnets_id
  security_groups_id = module.vpc.security_groups_id
  cluster_config     = var.cluster_config
  common_tags        = local.common_tags
  naming_prefix      = local.naming_prefix
}

resource "null_resource" "update_kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks --region us-east-1 update-kubeconfig --name ${var.cluster_config.name}"
  }
  depends_on = [module.eks]
}

################################################################################
# Create ingress-nginx namespace
################################################################################
resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
    labels = {
      name = "ingress-nginx"
    }
  }
  depends_on = [module.eks]
}

################################################################################
# Install NGINX Ingress Controller using Helm
################################################################################
resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name
  version    = "4.8.3"

  values = [
    yamlencode({
      controller = {
        service = {
          type = "LoadBalancer"
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-type"                              = "nlb"
            "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
          }
        }
        metrics = {
          enabled = true
          serviceMonitor = {
            enabled = false
          }
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace.ingress_nginx]
}

################################################################################
# Get Load Balancer information for ACM module
################################################################################
data "kubernetes_service" "nginx_ingress_controller" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
  }
  depends_on = [helm_release.nginx_ingress]
}

################################################################################
# Create ACM Certificate and DNS records
################################################################################
module "acm" {
  source = "./modules/acm"

  domain_name = var.domain_config.domain_name
  subject_alternative_names = [
    "*.${var.domain_config.domain_name}",
    var.domain_config.prometheus_subdomain,
    var.domain_config.grafana_subdomain
  ]

  prometheus_subdomain = var.domain_config.prometheus_subdomain
  grafana_subdomain    = var.domain_config.grafana_subdomain

  load_balancer_dns_name = data.kubernetes_service.nginx_ingress_controller.status.0.load_balancer.0.ingress.0.hostname
  load_balancer_zone_id  = "Z26RNL4JYFTOTI" # NLB zone ID for us-east-1

  common_tags   = local.common_tags
  naming_prefix = local.naming_prefix

  depends_on = [helm_release.nginx_ingress]
}

################################################################################
# Create cert-manager namespace
################################################################################
resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
    labels = {
      name = "cert-manager"
    }
  }
  depends_on = [module.eks]
}

################################################################################
# Install cert-manager using Helm
################################################################################
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name
  version    = "v1.13.3"

  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [kubernetes_namespace.cert_manager, module.acm]
}

################################################################################
# Create ClusterIssuer for Let's Encrypt using kubectl
################################################################################
resource "null_resource" "letsencrypt_prod" {
  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command = <<-EOT
      @"
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@${var.domain_config.domain_name}
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
"@ | kubectl apply -f -
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete clusterissuer letsencrypt-prod --ignore-not-found=true"
  }

  depends_on = [helm_release.cert_manager, null_resource.update_kubeconfig]
}

################################################################################
# Create monitoring namespace
################################################################################
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      name = "monitoring"
    }
  }
  depends_on = [module.eks]
}

################################################################################
# Install Prometheus using Helm (after nginx ingress)
################################################################################
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "55.5.0"

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          retention = "30d"
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp2"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "50Gi"
                  }
                }
              }
            }
          }
        }
        service = {
          type = "ClusterIP"
        }
        ingress = {
          enabled          = true
          ingressClassName = "nginx"
          hosts            = [var.domain_config.prometheus_subdomain]
          paths            = ["/"]
          tls = [{
            secretName = "prometheus-tls"
            hosts      = [var.domain_config.prometheus_subdomain]
          }]
          annotations = {
            "cert-manager.io/cluster-issuer"           = "letsencrypt-prod"
            "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
          }
        }
      }
      grafana = {
        enabled       = true
        adminPassword = "admin123"
        service = {
          type = "ClusterIP"
        }
        ingress = {
          enabled          = true
          ingressClassName = "nginx"
          hosts            = [var.domain_config.grafana_subdomain]
          path             = "/"
          tls = [{
            secretName = "grafana-tls"
            hosts      = [var.domain_config.grafana_subdomain]
          }]
          annotations = {
            "cert-manager.io/cluster-issuer"           = "letsencrypt-prod"
            "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
          }
        }
        persistence = {
          enabled          = true
          storageClassName = "gp2"
          size             = "10Gi"
        }
      }
      alertmanager = {
        enabled = true
        alertmanagerSpec = {
          storage = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp2"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "10Gi"
                  }
                }
              }
            }
          }
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace.monitoring, helm_release.nginx_ingress, null_resource.letsencrypt_prod, module.acm]
}

################################################################################
# Update NGINX Ingress to enable ServiceMonitor after Prometheus is installed
################################################################################
resource "helm_release" "nginx_ingress_with_monitoring" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name
  version    = "4.8.3"

  values = [
    yamlencode({
      controller = {
        service = {
          type = "LoadBalancer"
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-type"                              = "nlb"
            "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
          }
        }
        metrics = {
          enabled = true
          serviceMonitor = {
            enabled = true
            additionalLabels = {
              release = "prometheus"
            }
          }
        }
      }
    })
  ]

  depends_on = [helm_release.prometheus]
}

