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

/*
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
# Get the NLB hostname from nginx ingress controller
################################################################################
data "kubernetes_service" "nginx_ingress_controller" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
  }
  depends_on = [helm_release.nginx_ingress]
}

################################################################################
# Get Route53 hosted zone for chinmayto.com
################################################################################
data "aws_route53_zone" "main" {
  name         = "chinmayto.com"
  private_zone = false
}

################################################################################
# Create Route53 A records for Prometheus and Grafana
################################################################################
resource "aws_route53_record" "prometheus" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "prometheus.chinmayto.com"
  type    = "A"

  alias {
    name                   = data.kubernetes_service.nginx_ingress_controller.status.0.load_balancer.0.ingress.0.hostname
    zone_id                = "Z26RNL4JYFTOTI" # NLB zone ID for us-east-1
    evaluate_target_health = true
  }

  depends_on = [helm_release.nginx_ingress]
}

resource "aws_route53_record" "grafana" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "grafana.chinmayto.com"
  type    = "A"

  alias {
    name                   = data.kubernetes_service.nginx_ingress_controller.status.0.load_balancer.0.ingress.0.hostname
    zone_id                = "Z26RNL4JYFTOTI" # NLB zone ID for us-east-1
    evaluate_target_health = true
  }

  depends_on = [helm_release.nginx_ingress]
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
        }
        service = {
          type = "ClusterIP"
        }
        ingress = {
          enabled          = true
          ingressClassName = "nginx"
          hosts            = ["prometheus.chinmayto.com"]
          paths            = ["/"]
          annotations = {
            "nginx.ingress.kubernetes.io/rewrite-target" = "/"
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
          hosts            = ["grafana.chinmayto.com"]
          path             = "/"
          annotations = {
            "nginx.ingress.kubernetes.io/rewrite-target" = "/"
          }
        }
        persistence = {
          enabled = false
        }
      }
      alertmanager = {
        enabled = true
      }
    })
  ]

  depends_on = [kubernetes_namespace.monitoring, helm_release.nginx_ingress]
}

*/