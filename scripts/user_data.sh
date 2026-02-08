#!/bin/bash
# Bootstrap: instala Docker, monta EFS e sobe WordPress via docker-compose.
# O conteúdo do docker-compose é injetado pelo Terraform (arquivo do repositório).

set -e
yum update -y
yum install -y docker amazon-efs-utils

systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Docker Compose (binário standalone)
curl -sSL "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Monta o EFS (ID injetado pelo Terraform)
mkdir -p /mnt/efs
mount -t efs ${efs_id}:/ /mnt/efs
mkdir -p /mnt/efs/wp-content /mnt/efs/mysql-data

# Escreve docker-compose.yml (conteúdo do repositório, injetado em base64 pelo Terraform)
echo "${docker_compose_content_base64}" | base64 -d > /home/ec2-user/docker-compose.yml
chown ec2-user:ec2-user /home/ec2-user/docker-compose.yml

cd /home/ec2-user
/usr/local/bin/docker-compose up -d
