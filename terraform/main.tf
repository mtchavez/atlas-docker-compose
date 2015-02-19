# Configure the AWS Provider
provider "aws" {
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
    region = "${var.region}"
}

resource "atlas_artifact" "ubuntu-docker" {
    name = "mtchavez/ubuntu-docker"
    type = "aws.ami"
}

resource "aws_security_group" "allow_all" {
  name = "allow_all"
    description = "Allow all inbound traffic"

  ingress {
      from_port = 0
      to_port = 65535
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "docker-host" {
    ami = "${atlas_artifact.ubuntu-docker.metadata_full.region-us-west-2}"
    instance_type = "t2.micro"
    key_name = "personal-ec2"
    security_groups = ["${aws_security_group.allow_all.name}"]
}
