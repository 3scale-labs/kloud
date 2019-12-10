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

resource "aws_route53_record" "traefik" {
  zone_id = "${aws_route53_zone.this.zone_id}"
  name    = "*.hackfest.aws.mc.3sca.net"
  type    = "CNAME"
  ttl     = "30"
  records = ["a17de6e991a9911eabba112f9a62405d-956925070.us-east-1.elb.amazonaws.com"]
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

resource "aws_route53_record" "gcp_mc_threesca_net" {
  provider = aws.master
  zone_id  = data.aws_route53_zone.threesca_net.zone_id
  name     = "gcp.mc.3sca.net."
  type     = "NS"
  ttl      = "300"
  records = [
    "ns-cloud-b1.googledomains.com.",
    "ns-cloud-b2.googledomains.com.",
    "ns-cloud-b3.googledomains.com.",
    "ns-cloud-b4.googledomains.com.",
  ]
}


resource "aws_route53_record" "az_mc_threesca_net" {
  provider = aws.master
  zone_id  = data.aws_route53_zone.threesca_net.zone_id
  name     = "az.mc.3sca.net."
  type     = "NS"
  ttl      = "300"
  records = [
    "ns1-05.azure-dns.com.",
    "ns2-05.azure-dns.net.",
    "ns3-05.azure-dns.org.",
    "ns4-05.azure-dns.info.",
  ]
}

