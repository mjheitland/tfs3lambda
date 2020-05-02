#--- compute/variables.tf

variable "region" {
  description = "AWS region"
  type        = string
}
variable "project_name" {
  description = "project name is used as resource tag"
  type        = string
}
variable "key_name" {
  description = "name of keypair to access ec2 instances"
  type        = string
}
variable "public_key_path" {
  description = "file path on deployment machine to public rsa key to access ec2 instances"
  type        = string
}
variable "vpc1_id" {
  description = "id of vpc1"
  type        = string
}
variable "subpub1_id" {
  description = "id of public subnet 1"
  type        = string
}
variable "sgpub1_id" {
  description = "id of public security group"
  type        = string
}
variable "bucket" {
  description = "name of the bucket that stores the files"
  type        = string
}
variable "bucket_arn" {
  description = "arn of the bucket that stores the files"
  type        = string
}
