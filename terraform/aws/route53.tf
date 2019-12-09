module "aws_mc_zone_label" {
  #"git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.16.0"
  # git@github.com:roivaz/terraform-null-label.git
  source      = "git::https://github.com/roivaz/terraform-null-label.git"
  environment = local.environment
  project     = local.project
  workload    = local.workload
  type        = "r53z"
  tf_config   = local.tf_config
}

#
# Create the zone aws.mc.3sca.net in the 3scale-dev account
#
resource "aws_route53_zone" "this" {
  name = "aws.mc.3sca.net"
  tags = module.aws_mc_zone_label.tags
}

#
# Delegate the zone from the master account to the newly created zone
#
provider "aws" {
  alias   = "master"
  region  = "us-east-1"
  version = "~> 2.35"
}

data "aws_route53_zone" "threesca_net" {
  provider = aws.master
  name     = "3sca.net."
}

resource "aws_route53_record" "aws_mc_threesca_net" {
  provider = aws.master
  zone_id  = data.aws_route53_zone.threesca_net.zone_id
  name     = "aws.mc.3sca.net."
  type     = "NS"
  ttl      = "300"
  records  = aws_route53_zone.this.name_servers
}