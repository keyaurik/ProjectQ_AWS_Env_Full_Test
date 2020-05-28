#################################################################
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Licensed Materials - Property of IBM
#
# ©Copyright IBM Corp. 2017, 2018.
#
#################################################################

provider "aws" {
  version = "~> 2.0"
  region  = "${var.aws_region}"
}

module "camtags" {
  source = "../Modules/camtags"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-east-1"
}

variable "subnet_name" {
  description = "Subnet Name"
  default = ""
}

variable "aws_image_size" {
  description = "AWS Image Instance Size"
  default     = "t2.small"
}

data "aws_subnet" "selected" {
  filter {
    name   = "tag:Name"
    values = ["${var.subnet_name}"]
  }
}

variable "public_ssh_key_name" {
  description = "Name of the public SSH key used to connect to the virtual guest"
}

variable "public_ssh_key" {
  description = "Public SSH key used to connect to the virtual guest"
}

#Variable : AWS image name
variable "aws_image" {
  type        = "string"
  description = "AMI ID"
}
  
resource "tls_private_key" "ssh" {
    algorithm = "RSA"
}
resource "aws_key_pair" "auth" {
    key_name = "${var.aws_key_pair_name}"
    public_key = "${tls_private_key.ssh.public_key_openssh}"
}

resource "aws_key_pair" "fullenvtest" {
  key_name   = "${var.public_ssh_key_name}"
  public_key = "${var.public_ssh_key}"
}

resource "aws_instance" "fullenvtest" {
  instance_type = "${var.aws_image_size}"
  ami           = "${var.aws_image}"
  subnet_id     = "${data.aws_subnet.selected.id}"
  key_name      = "${aws_key_pair.fullenvtest.id}"
  tags          = "${module.camtags.tagsmap}"
}

output "ip_address" {
  value = "${length(aws_instance.fullenvtest.public_ip) > 0 ? aws_instance.fullenvtest.public_ip : aws_instance.fullenvtest.private_ip}"
}
