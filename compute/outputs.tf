#--- compute/outputs.tf

output "keypair_id" {
  value = "${join(", ", aws_key_pair.keypair.*.id)}"
}
output "provider_ids" {
  value = (aws_instance.provider.*.id)[0]
}
output "provider_public_ips" {
  value = "${join(", ", aws_instance.provider.*.public_ip)}"
}
output "consumer_id" {
  value = (aws_instance.consumer.*.id)[0]
}
output "consumer_public_ips" {
  value = "${join(", ", aws_instance.consumer.*.public_ip)}"
}
