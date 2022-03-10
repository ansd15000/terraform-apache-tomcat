output "web1" { value = aws_instance.web[0].id }
output "web2" { value = aws_instance.web[1].id }
output "was1" { value = aws_instance.was[0].id }
output "was2" { value = aws_instance.was[1].id }
output "nlb" { value = aws_lb.internal.dns_name }
output "alb" { value = aws_lb.external.dns_name}