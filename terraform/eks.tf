resource "aws_eks_cluster" "eks_cluster" {
  name     = var.eks_cluster_name
  role_arn   = aws_iam_role.ClusterRole.arn
  
  vpc_config {
      subnet_ids = [aws_subnet.public_1a.id, aws_subnet.public_1b.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.ClusterRole-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.ClusterRole-AmazonEKSVPCResourceController,
  ]
}

resource "aws_iam_role" "ClusterRole" {
  name = "eks-cluster-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}


resource "aws_iam_role_policy_attachment" "ClusterRole-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.ClusterRole.name
}

# Optionally, enable Security Groups for Pods
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "ClusterRole-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.ClusterRole.name
}


resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "eks_node_group"
  node_role_arn   = aws_iam_role.NodeGroupRole.arn
  subnet_ids      = [aws_subnet.public_1a.id, aws_subnet.public_1b.id]
  disk_size         = 10
  #instance_types    = ["m5.large"]

  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }

  #update_config {
  #  max_unavailable = 2
  #}

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.NodeGroupRole-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.NodeGroupRole-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.NodeGroupRole-AmazonEC2ContainerRegistryReadOnly,
  ]
  }


resource "aws_iam_role" "NodeGroupRole" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}


resource "aws_iam_role_policy_attachment" "NodeGroupRole-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.NodeGroupRole.name
}

resource "aws_iam_role_policy_attachment" "NodeGroupRole-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.NodeGroupRole.name
}

resource "aws_iam_role_policy_attachment" "NodeGroupRole-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.NodeGroupRole.name
}

resource "aws_cloudwatch_log_group" "cloudwatch_log_group" {
  # The log group name format is /aws/eks/<cluster-name>/cluster
  # Reference: https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html
  name              = "/aws/eks/${var.eks_cluster_name}/cluster"
  retention_in_days = 7

  # ... potentially other configuration ...
}
/*
resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = <<CONFIGMAPAWSAUTH
- rolearn: arn:aws:iam::[계정넘버]:user/[계정ID]
  username: admin
  groups:
    - system:masters
CONFIGMAPAWSAUTH
  }
}
*/