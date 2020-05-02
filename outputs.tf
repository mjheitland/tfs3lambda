#--- root/outputs.tf ---
output "project_name" {
  value = var.project_name
}

#--- storage
output "bucket_id" {
  value       = module.storage.id
}
output "bucket_arn" {
  value       = module.storage.arn
}
output "bucket_name" {
  value       = module.storage.name
}
output "bucket_domain_name" {
  value       = module.storage.bucket_domain_name
}
output "bucket_regional_domain_name" {
  value       = module.storage.bucket_regional_domain_name
}

#--- networking
output "vpc1_id" {
  value = module.networking.vpc1_id
}
output "igw1_id" {
  value = module.networking.igw1_id
}
output "subpub1_id" {
  value = module.networking.subpub1_id
}
output "sgpub1_id" {
  value = module.networking.sgpub1_id
}
output "rtpub1_id" {
  value = module.networking.rtpub1_id
}
output "rtpub1assoc_id" {
  value = module.networking.rtpub1assoc_id
}

#--- compute
output "keypair_id" {
  value = module.compute.keypair_id
}
output "provider_ids" {
  value = module.compute.provider_ids
}
output "provider_public_ips" {
  value = module.compute.provider_public_ips
}
output "consumer_id" {
  value = module.compute.consumer_id
}
output "consumer_public_ips" {
  value = module.compute.consumer_public_ips
}
