# -----------------------------------------------------------------------------
# Variáveis para o padrão WordPress HA com EFS
# Para usar a VPC padrão da conta, preencha terraform.tfvars ou use -var.
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "Região AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "ID da VPC onde criar ALB, EC2/ASG e EFS mount targets"
  type        = string
}

variable "public_subnets" {
  description = "Lista de IDs das subnets públicas (mín. 2 em AZs diferentes para o ALB)"
  type        = list(string)
}

variable "subnet_id" {
  description = "ID da subnet para o primeiro EFS mount target (Parte 4 expande para múltiplas AZs)"
  type        = string
}

variable "instance_type" {
  description = "Tipo da instância EC2 (ex.: t3.micro para free tier)"
  type        = string
  default     = "t3.micro"
}

variable "environment" {
  description = "Ambiente (ex.: dev, staging, prod) para tags"
  type        = string
  default     = "dev"
}
