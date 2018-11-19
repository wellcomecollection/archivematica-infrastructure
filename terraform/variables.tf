variable "AWS_REGION" {
  default = "eu-west-1"
}

# locally run: ssh-keygen -f archivematica-sshkey and add .pem extension to private key
variable "PATH_TO_PRIVATE_KEY" {
  default = "archivematica-sshkey2.pem"
}
variable "PATH_TO_PUBLIC_KEY" {
  default = "archivematica-sshkey2.pub"
}

variable archivematica_vpc_ip_cidr_range {
  default = "10.0.0.0/16"
}

variable "ECS_INSTANCE_TYPE" {
  default = "t2.medium"
}