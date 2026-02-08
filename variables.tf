# -----------------------------------------------------------------------------
# Variáveis para o padrão WordPress HA com EFS
# Preencha terraform.tfvars ou use -var (veja terraform.tfvars.example).
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "Região AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "ID da VPC onde criar ALB, EC2 e EFS mount targets"
  type        = string
}

variable "public_subnets" {
  description = "Lista de IDs das subnets públicas (mín. 2 em AZs diferentes para o ALB e para EFS mount targets em cada AZ)"
  type        = list(string)
}

variable "instance_type" {
  description = "Tipo da instância EC2 (ex.: t3.micro para free tier)"
  type        = string
  default     = "t3.micro"
}

variable "asg_min_size" {
  description = "Número mínimo de instâncias no Auto Scaling Group"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Número máximo de instâncias no Auto Scaling Group"
  type        = number
  default     = 2
}

variable "asg_desired_capacity" {
  description = "Capacidade desejada de instâncias no ASG"
  type        = number
  default     = 1
}

variable "environment" {
  description = "Ambiente (ex.: dev, staging, prod) para tags"
  type        = string
  default     = "dev"
}
