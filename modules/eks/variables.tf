variable "common_tags" {}
variable "naming_prefix" {}

variable "public_subnets_id" {}

variable "private_subnets_id" {}

variable "security_groups_id" {}

variable "cluster_config" {}

variable "node_groups" {
  type = list(object({
    name           = string
    instance_types = list(string)
    ami_type       = string
    capacity_type  = string
    disk_size      = number
    scaling_config = object({
      desired_size = number
      min_size     = number
      max_size     = number
    })
    update_config = object({
      max_unavailable = number
    })
  }))
  default = [
    {
      name           = "t3-medium-standard"
      instance_types = ["t3.medium"]
      ami_type       = "AL2023_x86_64_STANDARD"
      capacity_type  = "ON_DEMAND"
      disk_size      = 20
      scaling_config = {
        desired_size = 2
        max_size     = 3
        min_size     = 1
      }
      update_config = {
        max_unavailable = 1
      }
    },
    # {
    #   name           = "t3-medium-spot"
    #   instance_types = ["t3.medium"]
    #   ami_type       = "AL2023_x86_64_STANDARD"
    #   capacity_type  = "SPOT"
    #   disk_size      = 20
    #   scaling_config = {
    #     desired_size = 2
    #     max_size     = 3
    #     min_size     = 1
    #   }
    #   update_config = {
    #     max_unavailable = 1
    #   }
    # },
  ]

}

variable "addons" {
  type = map(object({
    name        = string
    version     = string
    most_recent = optional(bool)
  }))

  default = {
    kube-proxy = {
      name    = "kube-proxy"
      version = "v1.22.6-eksbuild.1"
    }
    vpc-cni = {
      name    = "vpc-cni"
      version = "v1.11.0-eksbuild.1"
    }
    coredns = {
      name    = "coredns"
      version = "v1.8.7-eksbuild.1"
    }
    aws-ebs-csi-driver = {
      name    = "aws-ebs-csi-driver"
      version = "v1.6.2-eksbuild.0"
    }
  }
}