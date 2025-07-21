variable "aws_region" {
  default = "ap-south-1"
}

variable "ami_id" {
  default = "ami-0f918f7e67a3323f0"
}

variable "key_name" {
  default = "k8s"
}

variable "my_ip" {
  default = "<myip>"  #add your Public IP
}

variable "github_webhook_ips" {
  type = set(string)
  default = [ "192.30.252.0/22", "185.199.108.0/22", "140.82.112.0/20", "143.55.64.0/20" ]  #need to update these IPs if it's get changed here https://api.github.com/meta
}
