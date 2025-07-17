resource "aws_security_group" "master_node" {
  name        = "${lower(local.project_slug)}-control-plane-master-sg"
  description = "Control Plane Master Node sg group"
  vpc_id      = var.network.vpc

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow all TCP egress traffic"
  }
}

resource "aws_security_group_rule" "master_github_runners_ssh" {
  for_each          = toset(["22", "6443"])
  security_group_id = aws_security_group.master_node.id
  type              = "ingress"
  description       = "Allow ssh traffic from GitHub Runners"
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  cidr_blocks       = var.runners_cidrs
}

resource "aws_security_group_rule" "etcd" {
  security_group_id        = aws_security_group.master_node.id
  type                     = "ingress"
  description              = "Allow access for etcd clients (control-plane) and leadership orchestration"
  from_port                = 2379
  to_port                  = 2380
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.master_node.id
}

resource "aws_security_group_rule" "from_master_to_master_cni" {
  security_group_id        = aws_security_group.master_node.id
  type                     = "ingress"
  description              = "Allow access from CNIs (VXLAN)"
  from_port                = 8472
  to_port                  = 8472
  protocol                 = "udp"
  source_security_group_id = aws_security_group.master_node.id
}

resource "aws_security_group_rule" "from_worker_to_master_cni" {
  security_group_id        = aws_security_group.master_node.id
  type                     = "ingress"
  description              = "Allow access from CNIs (VXLAN)"
  from_port                = 8472
  to_port                  = 8472
  protocol                 = "udp"
  source_security_group_id = aws_security_group.worker_node.id
}

resource "aws_security_group_rule" "from_master_to_master_nodes_kube_port_range" {
  for_each                 = toset(["10250", "10251", "10252", "10256"])
  security_group_id        = aws_security_group.master_node.id
  type                     = "ingress"
  description              = "Allow access to kubelet, kube-proxy, kube-scheduler"
  from_port                = each.value
  to_port                  = each.value
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.master_node.id
}

resource "aws_security_group_rule" "from_workers_to_master_nodes_kube_port_range" {
  for_each                 = toset(["10250", "10251", "10252", "10256"])
  security_group_id        = aws_security_group.master_node.id
  type                     = "ingress"
  description              = "Allow access to kubelet, kube-proxy, kube-scheduler"
  from_port                = each.value
  to_port                  = each.value
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.worker_node.id
}



resource "aws_security_group_rule" "control_plane_api_self" {
  for_each          = toset(["6443"])
  security_group_id = aws_security_group.master_node.id
  type              = "ingress"
  description       = "Allow access for other control planes sharing the security group"
  from_port         = tonumber(each.value)
  to_port           = tonumber(each.value)
  protocol          = "tcp"
  self              = true
}

resource "aws_security_group_rule" "from_master_to_master_rke2_comms_port" {
  security_group_id = aws_security_group.master_node.id
  type              = "ingress"
  description       = "Allow traffic on RKE2 port for node registration"
  from_port         = 9345
  to_port           = 9345
  protocol          = "tcp"
  self              = true
}

resource "aws_security_group_rule" "from_worker_to_master_rke2_comms_port" {
  security_group_id        = aws_security_group.master_node.id
  type                     = "ingress"
  description              = "Allow traffic on RKE2 port for node registration"
  from_port                = 9345
  to_port                  = 9345
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.worker_node.id
}

resource "aws_security_group_rule" "master_node_nodeport_range" {
  for_each          = toset(["tcp", "udp"])
  security_group_id = aws_security_group.master_node.id
  type              = "ingress"
  description       = "Allow ingress traffic to Kubernetes NodePort service port range"
  from_port         = 30000
  to_port           = 32767
  protocol          = each.value
  self              = true
}

resource "aws_security_group_rule" "worker_to_master_nodeport_range" {
  for_each                 = toset(["tcp", "udp"])
  security_group_id        = aws_security_group.master_node.id
  type                     = "ingress"
  description              = "Allow ingress traffic to Kubernetes NodePort service port range"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = each.value
  source_security_group_id = aws_security_group.worker_node.id
}

resource "aws_security_group" "worker_node" {
  name        = "${lower(local.project_slug)}-control-plane-worker-sg"
  description = "Control Plane Worker Node sg"
  vpc_id      = var.network.vpc

  ingress {
    from_port   = 31488
    to_port     = 31488
    protocol    = "tcp"
    cidr_blocks = ["10.12.3.8/32"]
    description = "allow all traffic from the load balancer"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow all TCP egress traffic"
  }
}

resource "aws_security_group_rule" "worker_github_runners_ssh" {
  for_each          = toset(["22", "6443"])
  security_group_id = aws_security_group.worker_node.id
  type              = "ingress"
  description       = "Allow ssh traffic from GitHub Runners"
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  cidr_blocks       = var.runners_cidrs
}

resource "aws_security_group_rule" "from_master_to_worker_rke2_comms_port" {
  security_group_id        = aws_security_group.worker_node.id
  type                     = "ingress"
  description              = "Allow traffic on RKE2 port for communication"
  from_port                = 9345
  to_port                  = 9345
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.master_node.id
}

resource "aws_security_group_rule" "from_worker_to_worker_rke2_comms_port" {
  security_group_id = aws_security_group.worker_node.id
  type              = "ingress"
  description       = "Allow traffic on RKE2 port for communication"
  from_port         = 9345
  to_port           = 9345
  protocol          = "tcp"
  self              = true
}

resource "aws_security_group_rule" "worker_self_nodeport_range" {
  for_each          = toset(["tcp", "udp"])
  security_group_id = aws_security_group.worker_node.id
  type              = "ingress"
  description       = "Allow ingress traffic to Kubernetes NodePort service port range"
  from_port         = 30000
  to_port           = 32767
  protocol          = each.value
  self              = true
}

resource "aws_security_group_rule" "master_to_node_nodeport_range" {
  for_each                 = toset(["tcp", "udp"])
  security_group_id        = aws_security_group.worker_node.id
  type                     = "ingress"
  description              = "Allow ingress traffic to Kubernetes NodePort service port range"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = each.value
  source_security_group_id = aws_security_group.master_node.id
}

resource "aws_security_group_rule" "from_master_to_worker_cni" {
  security_group_id        = aws_security_group.worker_node.id
  type                     = "ingress"
  description              = "Allow access from CNIs"
  from_port                = 8472
  to_port                  = 8472
  protocol                 = "udp"
  source_security_group_id = aws_security_group.master_node.id
}

resource "aws_security_group_rule" "from_worker_to_worker_cni" {
  security_group_id        = aws_security_group.worker_node.id
  type                     = "ingress"
  description              = "Allow access from CNIs"
  from_port                = 8472
  to_port                  = 8472
  protocol                 = "udp"
  source_security_group_id = aws_security_group.worker_node.id
}

resource "aws_security_group_rule" "ingress_acme_cidr_nodeport" {
  for_each          = toset(["tcp", "udp"])
  security_group_id = aws_security_group.worker_node.id
  type              = "ingress"
  description       = "Allow ingress traffic to Kubernetes NodePort service port range"
  from_port         = 30000
  to_port           = 32767
  protocol          = each.value
  cidr_blocks       = var.network.acme_cidrs
}

resource "aws_security_group_rule" "ingress_acme_cidr_ssl" {
  security_group_id = aws_security_group.worker_node.id
  type              = "ingress"
  description       = "Allow ingress traffic on ssl port"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.network.acme_cidrs
}

resource "aws_security_group_rule" "from_master_nodes_to_workers_kube_port_range" {
  for_each                 = toset(["10250", "10251", "10252", "10256"])
  security_group_id        = aws_security_group.worker_node.id
  type                     = "ingress"
  description              = "Allow access to kubelet, kube-proxy, kube-scheduler"
  from_port                = each.value
  to_port                  = each.value
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.master_node.id
}

resource "aws_security_group_rule" "from_workers_to_workers_kube_port_range" {
  for_each                 = toset(["10250", "10251", "10252", "10256"])
  security_group_id        = aws_security_group.worker_node.id
  type                     = "ingress"
  description              = "Allow access to kubelet, kube-proxy, kube-scheduler"
  from_port                = each.value
  to_port                  = each.value
  protocol                 = "tcp"
  self = true
}