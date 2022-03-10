resource "aws_vpc" "vpc" {
    cidr_block = var.cidr
    enable_dns_hostnames = true
    tags = {
        Name = var.service_name
    }
}

resource "aws_default_security_group" "all_allow" {
  vpc_id = aws_vpc.vpc.id

  ingress = [{
    description = "all allow"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids = []
    security_groups = []
    self = false
  }]

  egress = [{
      description = "all allow"
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = [ "0.0.0.0/0" ]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids = []
      security_groups = []
      self = false
  }]
  
  tags = {
    Name = "terraform all allow"
  }
}
