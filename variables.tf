#--- root/variables.tf
variable "region" {
  description = "AWS region"
  type        = string
}
variable "project_name" {
  description = "project name is used as resource tag"
  type        = string
  default     = "tfs3lambda"
}

#-------compute variables
variable "key_name" {
  description = "name of keypair to access ec2 instances"
  type        = string
  default     = "tfs3lambda"
}
variable "public_key_path" {
  description = "file path on deployment machine to public rsa key to access ec2 instances"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
