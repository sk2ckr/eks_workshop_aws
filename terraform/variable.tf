variable "image_name" {
  description = "Name of Docker image"
  type        = string
  default     = "demo-flask-backend"
}

variable "source_path" {
  description = "Path to Docker image source"
  type        = string
  default     = "amazon-eks-flask"
}

variable "tag" {
  description = "Tag to use for deployed Docker image"
  type        = string
  default     = "latest"
}

variable "hash_script" {
  description = "Path to script to generate hash of source contents"
  type        = string
  default     = ""
}

variable "push_script" {
  description = "Path to script to build and push Docker image"
  type        = string
  default     = ""
}

variable "eks_cluster_name" {
    type    = string    
    default = "eks-demo"
}

# common
variable "prefix" {
    default = "skuser07531"
}

variable "region" {
    default = "ap-northeast-2"
}
#for subnet
variable "az-1a" {
    default = "ap-northeast-2a"
}

variable "az-1b" {
    default = "ap-northeast-2c"
}

# for vpc
variable "vpc1-cidr" {
    default = "10.0.0.0/16"
}

variable "subnet1a-cidr" {
    default = "10.0.1.0/24"
}

variable "subnet1b-cidr" {
    default = "10.0.2.0/24"
}

# custom AMI (web server)
variable "amazon_linux" {
    default = "ami-0e2aa8454b3b2fb8e"
}

variable "alb_account_id" {
    default = "027434742980" // ap-northeast-2 Asia Pacific (Seoul) 600734575887
}

variable "cloud9-cidr" {
    default = "0.0.0.0/0" // cloud9 public ip addr
}