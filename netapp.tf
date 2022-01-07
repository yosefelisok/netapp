# main.tf

####################################################
# Variables
####################################################
variable "region" {
  default = "us-east-2"
}

variable "profile" {
  default = "default"
}

variable "vpc_cidr" {
  default = "10.192.0.0/16"
}

#variable "dev_cidrs" {
#  default  = "0.0.0.0/0"
#}

variable "public_subnets" {
  type    = list(string)
  default = ["10.192.10.0/24", "10.192.20.0/24"]
}

variable "ami" {
  default = "ami-0a5899928eba2e7bd"
}

#variable "instance_type" {
#  default = "t3.xlarge"
#}

variable "key_name" {
  default = "ec2-ebs-demo"
}

variable "key_path" {
  default = "/path/to/ec2-ebs-demo.pem"
}

variable "ebs_att_device_name" {
  default = "/dev/sdd"
}

####################################################
# Providers
####################################################
provider "aws" {
  region  = var.region
  profile = var.profile
  access_key = "AKIAWGJXH62MTV7NLZAC"
  secret_key = "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"
}


####################################################
# Data
####################################################
data "aws_availability_zones" "azs" {}


####################################################
# Resources
####################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2.0"
  name = "ec2-ebs-volume"
  cidr = var.vpc_cidr

  azs            = slice(data.aws_availability_zones.azs.names, 0, 2)
  public_subnets = var.public_subnets

  tags = {
    Name = "ec2-ebs-volume-demo"
  }
}

resource "aws_security_group" "ssh" {
  name        = "ssh-sg"
  description = "For SSH Connections to EC2"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description       = "Allow SSH Connections"
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    cidr_blocks       = ["10.0.0.3/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
 
resource "aws_instance" "single_ec2" {
  depends_on    = [ module.vpc ]
  key_name      = var.key_name
  ami           = var.ami
  instance_type = "t3.xlarge"
  user_data = <<-EOF
              #! /bin/bash     

              #-------------Mount the EBS volume-----------------
              sudo apt update -y
              sudo apt install xfsprogs -y
              sudo mkfs -t xfs /dev/nvme1n1
              sudo mkdir /data
              sudo mount /dev/nvme1n1 /data
              BLK_ID=$(sudo blkid /dev/nvme1n1 | cut -f2 -d" ")
              if [[ -z $BLK_ID ]]; then
              echo " no block ID found ... "
              exit 1
              fi
              echo "$BLK_ID     /data   xfs    defaults   0   2" | sudo tee --append /etc/fstab
              sudo mount -a
              echo "Finish!"

              EOF

 }

resource "aws_ebs_volume" "single_ec2_ebs" {
  availability_zone = aws_instance.single_ec2.availability_zone
  size              = 150
  tags = {
    Name = "ec2-ebs-single-demo"
  }
}

resource "aws_volume_attachment" "single_ec2_ebs_att" {
  device_name  = var.ebs_att_device_name
  volume_id    = aws_ebs_volume.single_ec2_ebs.id
  instance_id  = aws_instance.single_ec2.id
  force_detach = true


	}
