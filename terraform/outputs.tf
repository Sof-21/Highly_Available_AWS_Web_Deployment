# The below will output the public and private IPs of the instances and the DNS name of the ALB after terraform apply is run.

output "jump_box_public_ip" {
  description = "Public ip assigned to jump box for SSH access."
  value       = aws_instance.jump_box.public_ip
}

output "web_server_a_private_ip" {
  description = "Private ip assigned to web server A."
  value       = aws_instance.web_server_a.private_ip
}

output "web_server_b_private_ip" {
  description = "Private ip assigned to web server B."
  value       = aws_instance.web_server_b.private_ip
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer."
  value       = aws_lb.ha_lb.dns_name
}