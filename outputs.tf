# Outputs exibidos após terraform apply (ex.: URL do WordPress via ALB)

output "alb_dns_name" {
  description = "DNS do Application Load Balancer — use no navegador para acessar o WordPress"
  value       = aws_lb.app_lb.dns_name
}

output "alb_zone_id" {
  description = "Zone ID do ALB (útil para criar CNAME no Route 53)"
  value       = aws_lb.app_lb.zone_id
}
