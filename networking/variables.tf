#--- networking/variables.tf ---

variable "region" {
  description = "AWS region"
  type        = string
}
variable "project_name" {
  description = "project name is used as resource tag"
  type        = string
}
