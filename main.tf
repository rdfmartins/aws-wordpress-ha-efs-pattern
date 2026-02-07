# 1. Security Groups (Princípio do Menor Privilégio)
resource "aws_security_group" "alb_sg" {
  name        = "wordpress-alb-sg"
  description = "Allow HTTP from internet to ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from world"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "wordpress-alb-sg" }
}

resource "aws_security_group" "ec2_sg" {
  name        = "wordpress-ec2-sg"
  description = "Allow traffic from ALB only; NFS from self for EFS"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description = "NFS from same SG (EFS mount)"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    self        = true
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "wordpress-ec2-sg" }
}

resource "aws_security_group" "efs_sg" {
  name        = "wordpress-efs-sg"
  description = "Allow NFS from EC2 instances only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "NFS from EC2 SG"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "wordpress-efs-sg" }
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