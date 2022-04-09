# common
variable "prefix" {
    default = "skuser07531"
}

variable "region" {
    default = "us-west-1"
}
#for subnet
variable "az-1a" {
    default = "us-west-1b"
}

variable "az-1b" {
    default = "us-west-1c"
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