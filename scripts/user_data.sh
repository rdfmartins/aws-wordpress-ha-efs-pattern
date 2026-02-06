#!/bin/bash
# Atualiza o sistema
yum update -y
yum install -y docker amazon-efs-utils git

# Inicia o Docker
service docker start
usermod -a -G docker ec2-user
chkconfig docker on

# Instala Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# --- A MÁGICA do EFS ---
# Cria o diretório local
mkdir -p /mnt/efs

# Monta o EFS usando o ID injetado pelo Terraform
# (Isso garante que, se a EC2 morrer, a nova monta o mesmo disco)
mount -t efs ${efs_id}:/ /mnt/efs

# Garante que as pastas do WP existam no EFS
mkdir -p /mnt/efs/wp-content
mkdir -p /mnt/efs/mysql-data # (Opcional se usar DB em container)

# Baixa o Docker Compose do seu Repo (ou cria inline)
cat <<EOF > /home/ec2-user/docker-compose.yml
version: '3'
services:
  db:
    image: mysql:5.7
    volumes:
      - /mnt/efs/mysql-data:/var/lib/mysql # Persistência do DB no EFS
    environment:
      MYSQL_ROOT_PASSWORD: password
      MYSQL_DATABASE: wordpress
      
  wordpress:
    depends_on:
      - db
    image: wordpress:latest
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: root
      WORDPRESS_DB_PASSWORD: password
    volumes:
      - /mnt/efs/wp-content:/var/www/html/wp-content # AQUI ESTÁ A CONSISTÊNCIA [3]
EOF

# Sobe a aplicação
cd /home/ec2-user
/usr/local/bin/docker-compose up -d