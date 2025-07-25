################################################################################
# Create VPC and components
################################################################################

module "vpc" {
  source          = "./modules/vpc"
  networking      = var.networking
  security_groups = var.security_groups
  common_tags     = local.common_tags
  naming_prefix   = local.naming_prefix
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

