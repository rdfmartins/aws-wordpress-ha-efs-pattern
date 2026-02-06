# aws-wordpress-ha-efs-pattern
Arquitetura WordPress escalável na AWS usando EFS para persistência compartilhada entre contêineres Docker. Resolve inconsistências de dados em cenários de Auto Scaling por meio de Infraestrutura como Código (Terraform).
# Padrão de Arquitetura WordPress HA na AWS: Escala Stateful com EFS & Terraform

![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![AWS EFS](https://img.shields.io/badge/AWS_EFS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)

## 🏗 O Desafio de Engenharia: Persistência em Escala
Escalar aplicações legadas ou CMS (como WordPress) horizontalmente na nuvem introduz um problema crítico de **Consistência de Dados**.

Em uma arquitetura tradicional, o armazenamento é local (EBS). Em um cenário de **Auto Scaling**, isso gera inconsistência:
> *"Se a requisição bate no Container A, o plugin/upload está lá. Se o Load Balancer envia para o Container B, o arquivo não existe."*

O desafio é desacoplar a camada de armazenamento da camada computacional, permitindo que as instâncias EC2 sejam efêmeras (descartáveis) sem perda de dados.

## 💡 A Solução: Armazenamento Desacoplado (EFS)
Este repositório implementa uma arquitetura de **Alta Disponibilidade (HA)** que resolve o problema de estado utilizando o **AWS Elastic File System (EFS)**.

Ao montar volumes EFS diretamente nos containers Docker via script de *Bootstrapping* (User Data), garantimos:
1.  **Persistência Compartilhada:** O diretório `/wp-content` (uploads, temas, plugins) é único e compartilhado entre todas as instâncias em tempo real.
2.  **Escalabilidade Elástica:** Novas instâncias lançadas pelo Auto Scaling Group visualizam imediatamente os arquivos existentes.
3.  **Automação Total:** Toda a infraestrutura (Rede, Segurança, Storage, Compute) é provisionada via **Terraform**.

## 🛠 Componentes da Arquitetura
*   **Entrada:** Application Load Balancer (ALB) distribuindo tráfego.
*   **Compute:** Instâncias EC2 Amazon Linux provisionadas via Terraform.
*   **Containerização:** Docker e Docker Compose gerenciando a aplicação e o banco de dados.
*   **Storage:** AWS EFS montado no host e mapeado para `/var/www/html/wp-content` dentro do container.
*   **Segurança:** Security Groups encadeados (Princípio do Menor Privilégio).

## 🚀 Como Executar (Automação)

### Pré-requisitos
*   Conta AWS ativa.
*   Terraform instalado (ou use o **AWS CloudShell**).

### Passo a Passo
1.  **Clone o Repositório:**
    ```bash
    git clone https://github.com/seu-usuario/aws-wordpress-ha-efs-pattern.git
    cd aws-wordpress-ha-efs-pattern
    ```

2.  **Provisione a Infraestrutura:**
    ```bash
    terraform init
    terraform apply -auto-approve
    ```
    *O Terraform irá criar o EFS, Security Groups, ALB e a instância EC2. O script de `user_data` irá instalar o Docker e subir a aplicação automaticamente.*

3.  **Acesse a Aplicação:**
    Ao final, o Terraform exibirá o DNS do Load Balancer:
    ```bash
    Outputs:
    alb_dns_name = "wordpress-alb-123456789.us-east-1.elb.amazonaws.com"
    ```
    Cole este endereço no navegador para configurar o WordPress.

## 📂 Estrutura do Projeto
```text
.
├── main.tf           # Definição da Infraestrutura (EFS, EC2, ALB, SG)
├── variables.tf      # Variáveis parametrizadas
├── outputs.tf        # Outputs do Terraform (URL do ALB)
├── docker-compose.yml # Orquestração dos containers (WP + DB)
└── scripts/
    └── user_data.sh  # Script de Bootstrapping (Instalação Docker + Mount EFS)
