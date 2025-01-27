###### Output ######
# output "ETC_HOSTS_DETAILS" {
#   description = "Details for /etc/hosts"
#   value = "Refer scripts/etchostsBastion and scripts/etchostsWindows file for update(if needed) /etc/hosts or /c/Windows/System32/drivers/etc/hosts."
# }

output "Private_IP" {
  description = "List of private IP addresses assigned to the instances"
  value = aws_instance.my_ec2_instances.*.private_ip
}

output "Public_IP" {
  description = "List of Public IP addresses assigned to the instances"
  value = aws_instance.my_ec2_instances.*.public_ip
}

# output "Load_Balancer_URL" {
#   description = "URLs of the Load Balancers"
#   value = [
#     aws_lb.control_center_lb.dns_name,
#     aws_lb.sr_lb.dns_name,
#     aws_lb.kafka_connect_lb.dns_name
#   ]
# }

output "Route53_Records" {
  description = "Route 53 DNS records for all UIs"
  value = [
    aws_route53_record.control_center_record.fqdn,
    aws_route53_record.sr_record.fqdn,
    aws_route53_record.kafka_connect_record.fqdn
  ]
}
