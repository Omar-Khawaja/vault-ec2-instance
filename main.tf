provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "ec2-instance-test" {
  count                  = 1
  ami                    = "ami-0cfee17793b08a293"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.ec2_instance_test_sg.id}"]
  key_name               = var.key_name

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 8
    delete_on_termination = true
  }

  user_data = data.template_file.user_data.rendered

  tags = {
    Name = "vault-test-${count.index}"
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")
  vars = {
    VAULTVERSION  = var.vault_version
    CONSULVERSION = var.consul_version
  }
}

resource "aws_security_group" "ec2_instance_test_sg" {
  name = "test-cluster-sg"

# SSH access

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

# Vault web interface

  ingress {
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "test-cluster-sg"
  }
}

output "instance_ip" {
  value = ["${aws_instance.ec2-instance-test.*.public_ip}"]
}
