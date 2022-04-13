#
# Key Pair Creation
#
resource "aws_key_pair" "public_key" {
  key_name   = "${var.prefix}_public_key"
  public_key = file("~/.ssh/id_rsa.pub")
}
#
# provider creation
#
provider "aws" {
  region  = var.region
}
#
# vpc creation
#
resource "aws_vpc" "vpc1" {
  cidr_block       = var.vpc1-cidr

  enable_dns_hostnames = true
  enable_dns_support =true
  instance_tenancy ="default"
  tags = {
    Name = "${var.prefix}-vpc1"
  }
}
#
# subnet creation
#
resource "aws_subnet" "public_1a" {
  vpc_id            = aws_vpc.vpc1.id
  availability_zone = var.az-1a
  cidr_block        = var.subnet1a-cidr

  tags  = {
    Name = "${var.prefix}-public-1a"
  }
}

resource "aws_subnet" "public_1b" {
  vpc_id            = aws_vpc.vpc1.id
  availability_zone = var.az-1b
  cidr_block        = var.subnet1b-cidr

  tags  = {
    Name = "${var.prefix}-public_1b"
  }
}
#
# internet gateway creation
#
resource "aws_internet_gateway" "igw1" {
  vpc_id = aws_vpc.vpc1.id

  tags = {
    Name = "${var.prefix}-igw1"
  }
}
#
# routing table creation
#
resource "aws_route_table" "rt1" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw1.id
  }

  tags = {
    Name = "${var.prefix}-rt1"
  }
}

resource "aws_route_table_association" "rt1_public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.rt1.id
}

resource "aws_route_table_association" "rt1_public_1b" {
  subnet_id      = aws_subnet.public_1b.id
  route_table_id = aws_route_table.rt1.id
}
/*
#
# default security group creation for alb
#
resource "aws_default_security_group" "sg1_default" {
  vpc_id = aws_vpc.vpc1.id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-sg1_default"
  }
}
#
# alb, alb target group, alb listener creation
#
resource "aws_alb" "alb1" {
    name = "${var.prefix}-alb1"
    internal = false
    security_groups = [aws_security_group.sg1_ec2.id]
    subnets = [
        aws_subnet.public_1a.id,
        aws_subnet.public_1b.id
    ]
    tags = {
        Name = "${var.prefix}-ALB1"
    }
    lifecycle { create_before_destroy = true }
}

resource "aws_alb_target_group" "frontend1" {
    name = "${var.prefix}-frontend1-target-group"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.vpc1.id
    health_check {
        interval = 30
        path = "/"
        healthy_threshold = 3
        unhealthy_threshold = 3
    }
    tags = { Name = "${var.prefix}-Frontend1 Target Group" }
}

resource "aws_alb_listener" "http1" {
    load_balancer_arn = aws_alb.alb1.arn
    port = "80"
    protocol = "HTTP"
    default_action {
        target_group_arn = aws_alb_target_group.frontend1.arn
        type = "forward"
    }
}
#
# ec2 security group creation
#
resource "aws_security_group" "sg1_ec2" {
  name        = "allow_http_ssh"
  description = "Allow HTTP/SSH inbound connections"
  vpc_id = aws_vpc.vpc1.id

  //allow http 80 port from alb
  ingress { 
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  //allow ssh 22 port from my_ip(cloud9)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.cloud9-cidr]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow HTTP/SSH Security Group"
  }
}
#
# ec2 autoscaling configuration
#
resource "aws_iam_instance_profile" "web1_profile" {
  name = "${var.prefix}-web1_profile"
  role = aws_iam_role.WebAppRole.name
}

resource "aws_launch_configuration" "web1" {
  name_prefix = "${var.prefix}-autoscaling-web1-"
  iam_instance_profile = aws_iam_instance_profile.web1_profile.name

  image_id = var.amazon_linux
  instance_type = "t2.micro"
  key_name = aws_key_pair.public_key.key_name
  security_groups = [
    "${aws_security_group.sg1_ec2.id}",
    "${aws_default_security_group.sg1_default.id}",
  ]
  associate_public_ip_address = true
    
  lifecycle {
    create_before_destroy = true
  }
  user_data = <<EOF
    #!/bin/bash
    sudo yum install -y aws-cli
    sudo yum install -y git
    cd /home/ec2-user/
    sudo wget https://aws-codedeploy-${var.region}.s3.amazonaws.com/latest/codedeploy-agent.noarch.rpm
    sudo yum install -y ruby
    sudo yum -y install codedeploy-agent.noarch.rpm
    sudo yum -y install tomcat
    sudo ln -s /usr/sbin/tomcat /usr/sbin/tomcat7
    sudo mv /usr/share/tomcat /usr/share/tomcat7
    sudo systemctl start codedeploy-agent.service
	EOF
}
#
# autoscaling group creation
#
resource "aws_autoscaling_group" "web1" {
  name = "${aws_launch_configuration.web1.name}-asg"

  min_size             = 1
  desired_capacity     = 2
  max_size             = 3

  health_check_type    = "ELB"

  launch_configuration = aws_launch_configuration.web1.name

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity="1Minute"

  vpc_zone_identifier  = [
    aws_subnet.public_1a.id,
    aws_subnet.public_1b.id
  ]

  # Required to redeploy without an outage.
  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.prefix}-web1-autoscaling"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_attachment" "asg1-attachment" {
  autoscaling_group_name = aws_autoscaling_group.web1.id
  alb_target_group_arn   = aws_alb_target_group.frontend1.arn
}
#
#  autoscaling policy SK.LEE
#
resource "aws_autoscaling_policy" "web1_scaling_policy" {
  name                      = "${var.prefix}-web1-tracking-policy"
  policy_type               = "TargetTrackingScaling"
  autoscaling_group_name    = aws_autoscaling_group.web1.name
  estimated_instance_warmup = 200

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label = "${aws_alb.alb1.arn_suffix}/${aws_alb_target_group.frontend1.arn_suffix}"
    }
    
    target_value = "1" #ALBRequestCountPerTarget Request 1
  }
}
#
#
#
#
#
#########################################################
#  CIDE Pipeline AWS Role Creation
#########################################################
#
#
#
#
#
#
# AWS Management Consol Account ID Import
#
data "aws_caller_identity" "current" {}
#
# S3 Bucket creation for CodePipeline
#
resource "aws_s3_bucket" "S3Bucket" {
    bucket = "skcc-cicd-workshop-${var.region}-${var.prefix}-${data.aws_caller_identity.current.account_id}"
    
    versioning {
        enabled = true
    }
    
	tags = {
		Name = "CICDWorkshop-S3Bucket"
	}
}
#
# Build Role Creation
#
resource "aws_iam_role" "BuildTrustRole" {
    name = "${var.prefix}-BuildTrustRole"
    
    assume_role_policy = <<-EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "1",
                "Effect": "Allow",
                "Principal": {
                    "Service": [
                        "codebuild.amazonaws.com"
                    ]
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }
    EOF
    path = "/"
}

resource "aws_iam_role_policy" "CodeBuildRolePolicy" {
    name = "${var.prefix}-CodeBuildRolePolicy"
    role = aws_iam_role.BuildTrustRole.id

    policy = <<-EOF
    {
      "Version": "2012-10-17",
          "Statement": [
            {
              "Sid": "CloudWatchLogsPolicy",
              "Effect": "Allow",
              "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
              ],
              "Resource": [
                "*"
              ]
            },
            {
              "Sid": "CodeCommitPolicy",
              "Effect": "Allow",
              "Action": [
                "codecommit:GitPull"
              ],
              "Resource": [
                "*"
              ]
            },
            {
              "Sid": "S3GetObjectPolicy",
              "Effect": "Allow",
              "Action": [
                "s3:GetObject",
                "s3:GetObjectVersion"
              ],
              "Resource": [
                "*"
              ]
            },
            {
              "Sid": "S3PutObjectPolicy",
              "Effect": "Allow",
              "Action": [
                "s3:PutObject"
              ],
              "Resource": [
                "*"
              ]
            },
            {
              "Sid": "OtherPolicies",
              "Effect": "Allow",
              "Action": [
                "ssm:GetParameters",
                "ecr:*"
              ],
              "Resource": [
                "*"
              ]
            }
          ]
    }
    EOF
}
#
# Deploy Role Creation
#
resource "aws_iam_role" "DeployTrustRole" {
    name = "${var.prefix}-DeployTrustRole"
    
    assume_role_policy = <<-EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid" : "",
                "Effect" : "Allow",
                "Principal" : {
                    "Service": [
                        "codedeploy.amazonaws.com"
                    ]
                },
                "Action" : "sts:AssumeRole"
            }
        ]
    }
    EOF
    path = "/"
}

resource "aws_iam_role_policy" "CodeDeployRolePolicy" {
    name = "${var.prefix}-CodeDeployRolePolicy"
    role = aws_iam_role.DeployTrustRole.id

    policy = <<-EOF
    {
        "Version": "2012-10-17",
        "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:CompleteLifecycleAction",
                "autoscaling:DeleteLifecycleHook",
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeLifecycleHooks",
                "autoscaling:PutLifecycleHook",
                "autoscaling:RecordLifecycleActionHeartbeat",
                "autoscaling:CreateAutoScalingGroup",
                "autoscaling:UpdateAutoScalingGroup",
                "autoscaling:EnableMetricsCollection",
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribePolicies",
                "autoscaling:DescribeScheduledActions",
                "autoscaling:DescribeNotificationConfigurations",
                "autoscaling:DescribeLifecycleHooks",
                "autoscaling:SuspendProcesses",
                "autoscaling:ResumeProcesses",
                "autoscaling:AttachLoadBalancers",
                "autoscaling:AttachLoadBalancerTargetGroups",
                "autoscaling:PutScalingPolicy",
                "autoscaling:PutScheduledUpdateGroupAction",
                "autoscaling:PutNotificationConfiguration",
                "autoscaling:PutLifecycleHook",
                "autoscaling:DescribeScalingActivities",
                "autoscaling:DeleteAutoScalingGroup",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceStatus",
                "ec2:TerminateInstances",
                "tag:GetResources",
                "sns:Publish",
                "cloudwatch:DescribeAlarms",
                "cloudwatch:PutMetricAlarm",
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:DescribeInstanceHealth",
                "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
                "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
                "elasticloadbalancing:DescribeTargetGroups",
                "elasticloadbalancing:DescribeTargetHealth",
                "elasticloadbalancing:RegisterTargets",
                "elasticloadbalancing:DeregisterTargets"
            ],
            "Resource": "*"
        }]
    }
    EOF
}
#
# Pipeline Role Creation
#
resource "aws_iam_role" "PipelineTrustRole" {
    name = "${var.prefix}-PipelineTrustRole"
    
    assume_role_policy = <<-EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "1",
                "Effect": "Allow",
                "Principal": {
                    "Service": [
                        "codepipeline.amazonaws.com"
                    ]
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }
    EOF
    path = "/"
}

resource "aws_iam_role_policy" "CodePipelinieRolePolicy" {
    name = "${var.prefix}-CodePipelineRolePolicy"
    role = aws_iam_role.PipelineTrustRole.id

    policy = <<-EOF
    {
        "Version": "2012-10-17",
        "Statement": [
        {
            "Action": [
                "s3:*"
            ],
            "Resource": ["*"],
            "Effect": "Allow"
        },
        {
            "Action": [
                "codecommit:GetBranch",
                "codecommit:GetCommit",
                "codecommit:UploadArchive",
                "codecommit:GetUploadArchiveStatus",
                "codecommit:CancelUploadArchive"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codepipeline:*",
                "iam:ListRoles",
                "iam:PassRole",
                "codedeploy:CreateDeployment",
                "codedeploy:GetApplicationRevision",
                "codedeploy:GetDeployment",
                "codedeploy:GetDeploymentConfig",
                "codedeploy:RegisterApplicationRevision",
                "lambda:*",
                "sns:*",
                "ecs:*",
                "ecr:*"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codebuild:StartBuild",
                "codebuild:StopBuild",
                "codebuild:BatchGet*",
                "codebuild:Get*",
                "codebuild:List*",
                "codecommit:GetBranch",
                "codecommit:GetCommit",
                "codecommit:GetRepository",
                "codecommit:ListBranches",
                "s3:GetBucketLocation",
                "s3:ListAllMyBuckets"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Action": [
                "logs:GetLogEvents"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:logs:*:*:log-group:/aws/codebuild/*:log-stream:*"
        }]
    }
    EOF
}
#
# Lambda Role Creation
#
resource "aws_iam_role" "CodePipelineLambdaExecRole" {
    name = "${var.prefix}-CodePipelineLambdaExecRole"
    
    assume_role_policy = <<-EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "1",
                "Effect": "Allow",
                "Principal": {
                    "Service": [
                        "lambda.amazonaws.com"
                    ]
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }
    EOF
    path = "/"
}

resource "aws_iam_role_policy" "CodePipelineLambdaExecPolicy" {
    name = "${var.prefix}-CodePipelineLambdaExecPolicy"
    role = aws_iam_role.CodePipelineLambdaExecRole.id

    policy = <<-EOF
    {
        "Version": "2012-10-17",
        "Statement": [
        {
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Action": [
                "codepipeline:PutJobSuccessResult",
                "codepipeline:PutJobFailureResult"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }]
    }
    EOF
}
#
### IAM Role Createion (EC2 인스턴스에 WebApp 소스 입력 역할, 권한 부여)
#
resource "aws_iam_role" "WebAppRole" {
    name = "${var.prefix}-WebAppRole"
    
    assume_role_policy = <<-EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "",
                "Effect": "Allow",
                "Principal": {
                    "Service": "ec2.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }
    EOF
    path = "/"
}

resource "aws_iam_role_policy" "WebAppRolePolicy" {
    name = "${var.prefix}-BackendRole"
    role = aws_iam_role.WebAppRole.id

    policy = <<-EOF
    {
        "Version": "2012-10-17",
        "Statement": [
        {
            "Action": [
                "autoscaling:Describe*",
                "autoscaling:EnterStandby",
                "autoscaling:ExitStandby",
                "autoscaling:UpdateAutoScalingGroup"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceStatus"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "s3:Get*",
                "s3:List*"
            ],
            "Resource": [
                "arn:aws:s3:::cicd-workshop-us-west-1-590526570343",
                "arn:aws:s3:::cicd-workshop-us-west-1-590526570343/*",
                "arn:aws:s3:::codepipeline-*"
            ],
            "Effect": "Allow"
        }]
    }
    EOF
}

resource "aws_iam_role_policy" "AmazonEC2ReadOnlyAccessPolicy" {
    name = "${var.prefix}-AmazonEC2ReadOnlyAccessPolicy"
    role = aws_iam_role.WebAppRole.id

    policy = <<-EOF
    {
        "Version": "2012-10-17",
        "Statement": [
        {
            "Effect": "Allow",
            "Action": "ec2:Describe*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "elasticloadbalancing:Describe*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:ListMetrics",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:Describe*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "autoscaling:Describe*",
            "Resource": "*"
        }]
    }
    EOF
}

resource "aws_iam_role_policy" "AWSCodeDeployReadOnlyAccessPolicy" {
    name = "${var.prefix}-AWSCodeDeployReadOnlyAccessPolicy"
    role = aws_iam_role.WebAppRole.id

    policy = <<-EOF
    {
        "Version": "2012-10-17",
        "Statement": [
        {
            "Action": [
                "codedeploy:Batch*",
                "codedeploy:Get*",
                "codedeploy:List*"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Sid": "CodeStarNotificationsPowerUserAccess",
            "Effect": "Allow",
            "Action": [
                "codestar-notifications:DescribeNotificationRule"
            ],
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "codestar-notifications:NotificationsForResource": "arn:aws:codedeploy:*"
                }
            }
        },
        {
            "Sid": "CodeStarNotificationsListAccess",
            "Effect": "Allow",
            "Action": [
                "codestar-notifications:ListNotificationRules",
                "codestar-notifications:ListEventTypes",
                "codestar-notifications:ListTargets"
            ],
            "Resource": "*"
        }]
    }
    EOF
}
*/