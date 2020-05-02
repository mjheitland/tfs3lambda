#--- compute/outputs.tf

output "keypair_id" {
  value = "${join(", ", aws_key_pair.keypair.*.id)}"
}
output "provider_ids" {
  value = "${join(", ", aws_instance.provider.*.id)}"
}
output "provider_public_ips" {
  value = "${join(", ", aws_instance.provider.*.public_ip)}"
}
output "consumer_ids" {
  value = "${join(", ", aws_instance.consumer.*.id)}"
}
output "consumer_public_ips" {
  value = "${join(", ", aws_instance.consumer.*.public_ip)}"
}
