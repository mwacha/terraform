provider "aws" {
  region = "${var.region}"
}

terraform {
  backend "s3" {
    bucket = "mwacha-bucket-dev"
    key    = "ec2/ec2.tfstate"
    region = "us-east-1"
  }
}

locals {
  conn_type    = "ssh"
  conn_user    = "ec2-user"
  conn_timeout = "4m"

  # conn_key     = "${tls_private_key.pkey.private_key_pem}"

  conn_key = "${file("F:/cursos/cursoterraform.pem")}"
}

resource "aws_instance" "web" {
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
  key_name      = "cursoterraform"

  provisioner "file" {
    source      = "2019-01-26.log"
    destination = "/tmp/file.log"

    connection {
      type        = "${local.conn_type}"
      user        = "${local.conn_user}"
      timeout     = "${local.conn_timeout}"
      host        = self.public_ip
      private_key = "${local.conn_key}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 50",
      "echo \"[UPDATING THE SYSTEM]\"",
      "sudo yum update -y",
      "echo \"[INSTALLING HTTPD]\"",
      "sudo yum install -y httpd",
      "echo \"[STARTING HTTPD]\"",
      "sudo service httpd start",
      "sudo chkconfig httpd on",
      "echo \"[FINISHING]\"",
      "sleep 50",
    ]

    connection {
      type        = "${local.conn_type}"
      user        = "${local.conn_user}"
      timeout     = "${local.conn_timeout}"
      host        = self.public_ip
      private_key = "${local.conn_key}"
    }
  }
}

resource "null_resource" "null" {
  provisioner "local-exec" {
    command = "echo ${aws_instance.web.id}:${aws_instance.web.public_ip} >> public_ips.txt"
  }
}

resource "tls_private_key" "pkey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "keypair" {
  key_name   = "mwacha-${var.env}"
  public_key = "${tls_private_key.pkey.public_key_openssh}"
}
