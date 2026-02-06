# 1. Security Groups (O "Castelo")
resource "aws_security_group" "alb_sg" {
  name = "alb-sg"
  description = "Allow HTTP from world"
  # Ingress porta 80 liberada para 0.0.0.0/0
}

resource "aws_security_group" "ec2_sg" {
  name = "wordpress-ec2-sg"
  description = "Allow traffic from ALB only"
  # Ingress porta 80 vindo APENAS do security_group do ALB (Segurança!)
  # Ingress porta 2049 (NFS) vindo do próprio SG (para montar EFS)
}

resource "aws_security_group" "efs_sg" {
  name = "efs-sg"
  # Ingress porta 2049 vindo do ec2_sg
}

# 2. O Elastic File System (O Coração da Persistência)
resource "aws_efs_file_system" "wordpress_efs" {
  creation_token = "wordpress-efs"
  encrypted      = true
  tags = { Name = "Wordpress-EFS" }
}

resource "aws_efs_mount_target" "mount" {
  # Cria um mount target em cada subnet para Alta Disponibilidade
  file_system_id  = aws_efs_file_system.wordpress_efs.id
  subnet_id       = var.subnet_id # Use count ou for_each para múltiplas subnets
  security_groups = [aws_security_group.efs_sg.id]
}

# 3. O Load Balancer (ALB)
resource "aws_lb" "app_lb" {
  name               = "wordpress-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnets
}

# 4. A Instância EC2 (Onde roda o Docker)
resource "aws_instance" "app_server" {
  ami           = "ami-0c7217cdde317cfec" # Exemplo Amazon Linux 2023
  instance_type = "t3.micro" # Free tier
  security_groups = [aws_security_group.ec2_sg.name]

  # AUTOMAÇÃO:
  # Injetamos o ID do EFS dentro do script de User Data
  user_data = templatefile("${path.module}/scripts/user_data.sh", {
    efs_id = aws_efs_file_system.wordpress_efs.id
  })

  tags = { Name = "Wordpress-Docker-Host" }
}