resource "aws_security_group" "management_cluster" {
  name        = "${lower(local.project_slug)}-management-sg"
  description = "Allow all inbound traffic from specific IP Ranges and allow all outbound traffic"
  vpc_id      = var.network.vpc

  ingress {
    to_port     = 0
    protocol    = "-1"
    from_port   = 0
    self        = true
    cidr_blocks = ["10.12.0.0/16", "10.20.0.0/16", "10.20.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all TCP egress traffic"
  }
}

resource "aws_security_group_rule" "allow_nlb_traffic_on_rke2_server_port" {
  security_group_id = aws_security_group.management_cluster.id
  type              = "ingress"
  description       = "Allow HTTP traffic from NLB"
  from_port         = 9345
  to_port           = 9345
  protocol          = "tcp"
  cidr_blocks       = ["10.1.2.3/32", "10.1.2.4/32", "10.1.2.14/32", "10.1.2.5/32", "10.1.2.7/32"]
}

resource "aws_security_group_rule" "allow_nlb_traffic_on_rancher_server_port" {
  security_group_id = aws_security_group.management_cluster.id
  type              = "ingress"
  description       = "Allow HTTP traffic from NLB"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["10.1.2.3/32", "10.1.2.4/32", "10.1.22.4/32", "10.1.2.5/32", "10.1.2.7/32"]
}

resource "aws_security_group_rule" "allow_alb_sg_traffic" {
  security_group_id = aws_security_group.management_cluster.id
  type              = "ingress"
  description       = "Allow ingress traffic from security group"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["10.1.12.8/32"]
}

resource "aws_security_group_rule" "allow_ingress_traffic_other_nodes" {
  security_group_id = aws_security_group.management_cluster.id
  type              = "ingress"
  description       = "Allow ingress communication between nodes"
  from_port         = 0
  to_port           = "-1"
  protocol          = 0
  self              = true
}

resource "aws_security_group_rule" "allow_ssh_ingress_traffic_from_ssvc_vpc" {
  security_group_id = aws_security_group.management_cluster.id
  type              = "ingress"
  description       = "Allow ssh ingress from other vpc"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["10.13.20.0/25", "100.7.0.0/20", "100.59.0.0/20"]
}

resource "aws_security_group_rule" "allow_ssh_ingress_traffic_from_onprem_workloads" {
  security_group_id = aws_security_group.management_cluster.id
  type              = "ingress"
  description       = "Allow tls traffic from on-prem workloads"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = tolist(var.network.onprem_cidrs)
}