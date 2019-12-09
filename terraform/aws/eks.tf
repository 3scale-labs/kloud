data "aws_availability_zones" "available" {
}

module "vpc_label" {
  source      = "git::https://github.com/roivaz/terraform-null-label.git"
  environment = local.environment
  project     = local.project
  workload    = local.workload
  type        = "vpc"
  tf_config   = local.tf_config
}

module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "~> 2.6"
  name                 = module.vpc_label.id
  cidr                 = "172.16.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
  public_subnets       = ["172.16.4.0/24", "172.16.5.0/24", "172.16.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  tags = {
    "kubernetes.io/cluster/${module.eks_label.id}" = "shared"
  }
  public_subnet_tags = {
    "kubernetes.io/cluster/${module.eks_label.id}" = "shared"
    "kubernetes.io/role/elb"                       = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/cluster/${module.eks_label.id}" = "shared"
    "kubernetes.io/role/internal-elb"              = "1"
  }
}

module "eks_label" {
  source      = "git::https://github.com/roivaz/terraform-null-label.git"
  environment = local.environment
  project     = local.project
  workload    = local.workload
  type        = "eks"
  tf_config   = local.tf_config
}

module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  version      = "v7.0.0"
  cluster_name = module.eks_label.id
  subnets      = module.vpc.private_subnets
  tags         = module.eks_label.tags
  vpc_id       = module.vpc.vpc_id
  worker_groups = [
    {
      name                 = "worker-group-1"
      instance_type        = "t3.medium"
      asg_desired_capacity = 2
      # additional_security_group_ids = [aws_security_group.worker_group.id]
    }
  ]
  kubeconfig_aws_authenticator_command_args = [
    "token",
    "-i",
    module.eks_label.id,
    "-r",
    "arn:aws:iam::396994816590:role/OrganizationAccountAccessRole"
  ]
}

provider "kubernetes" {
  load_config_file       = false
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "aws-iam-authenticator"
    args = [
      "token",
      "-i",
      module.eks_label.id,
      "-r",
      "arn:aws:iam::396994816590:role/OrganizationAccountAccessRole"
    ]
  }
}

resource "kubernetes_service_account" "admin" {
  metadata {
    name      = "admin-user"
    namespace = "default"
  }
}

resource "kubernetes_cluster_role_binding" "admin" {
  metadata {
    name = "admin-user"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "admin-user"
    namespace = "default"
  }
}