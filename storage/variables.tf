variable "bucket" {
  description = "The name of the bucket."
  type        = string
}

variable "use_account_alias_prefix" {
  description = "Whether to prefix the bucket name with the AWS account alias."
  type        = string
  default     = false
}

variable "custom_bucket_policy" {
  description = "JSON formatted bucket policy to attach to the bucket."
  type        = string
  default     = ""
}

variable "logging_bucket" {
  description = "The S3 bucket to send S3 access logs."
  type        = string
  default     = ""
}

variable "tags" {
  description = "A mapping of tags to assign to the bucket."
  default     = {}
  type        = map(string)
}

variable "force_destroy" {
  type        = bool
  default     = false
  description = "A boolean that indicates all objects (including any locked objects) should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable."
}

variable "enable_bucket_inventory" {
  type        = bool
  default     = false
  description = "If set to true, Bucket Inventory will be enabled."
}

variable "enable_versioning" {
  type        = bool
  default     = false
  description = "If set to true, bucket objects (i.e. files) will be versioned."
}

variable "enable_lifecycle" {
  type        = bool
  default     = false
  description = "If set to true, life cycle will be enabled. Older objects will be moved to a less expensive S3 storage option."
}

variable "inventory_bucket_format" {
  type        = string
  default     = "ORC"
  description = "The format for the inventory file. Default is ORC. Options are ORC or CSV."
}

variable "schedule_frequency" {
  type        = string
  default     = "Weekly"
  description = "The S3 bucket inventory frequency. Defaults to Weekly. Options are 'Weekly' or 'Daily'."
}
