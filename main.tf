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
  tags           = { Name = "Wordpress-EFS" }
}

# Parte 4: um mount target por subnet pública (HA — EFS acessível em todas as AZs)
# Assim, instâncias em qualquer uma das subnets conseguem montar o EFS.
resource "aws_efs_mount_target" "mount" {
  for_each = toset(var.public_subnets)

  file_system_id  = aws_efs_file_system.wordpress_efs.id
  subnet_id       = each.value
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

# -----------------------------------------------------------------------------
# Parte 2: Target group e listener (ALB encaminha para o target group)
# -----------------------------------------------------------------------------
resource "aws_lb_target_group" "wordpress" {
  name     = "wordpress-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }

  tags = { Name = "wordpress-tg" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress.arn
  }
}

# -----------------------------------------------------------------------------
# Parte 3: Auto Scaling Group (múltiplas instâncias em 2 subnets/AZs)
# As instâncias usam o mesmo user_data (mount EFS + docker-compose) e são
# registradas automaticamente no target group.
# -----------------------------------------------------------------------------
resource "aws_launch_template" "wordpress" {
  name_prefix   = "wordpress-"
  image_id      = "ami-0c7217cdde317cfec" # Amazon Linux 2023 (us-east-1)
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = base64encode(templatefile("${path.module}/scripts/user_data.sh", {
    efs_id                      = aws_efs_file_system.wordpress_efs.id
    docker_compose_content_base64 = base64encode(file("${path.module}/docker-compose.yml"))
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "Wordpress-Docker-Host" }
  }

  tags = { Name = "wordpress-lt" }
}

resource "aws_autoscaling_group" "wordpress" {
  name                = "wordpress-asg"
  vpc_zone_identifier = var.public_subnets
  target_group_arns   = [aws_lb_target_group.wordpress.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  launch_template {
    id      = aws_launch_template.wordpress.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "Wordpress-Docker-Host"
    propagate_at_launch  = true
  }
}