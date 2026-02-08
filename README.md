# aws-wordpress-ha-efs-pattern

Arquitetura WordPress escalável na AWS usando EFS para persistência compartilhada entre contêineres Docker. Resolve inconsistências de dados em cenários de Auto Scaling por meio de Infraestrutura como Código (Terraform).

## Padrão de Arquitetura WordPress HA na AWS: Escala Stateful com EFS & Terraform

![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![AWS EFS](https://img.shields.io/badge/AWS_EFS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)

---

## 🏗 O Desafio de Engenharia: Persistência em Escala

Escalar aplicações legadas ou CMS (como WordPress) horizontalmente na nuvem introduz um problema crítico de **Consistência de Dados**.

Em uma arquitetura tradicional, o armazenamento é local (EBS). Em um cenário de **Auto Scaling**, isso gera inconsistência:

> *"Se a requisição bate no Container A, o plugin/upload está lá. Se o Load Balancer envia para o Container B, o arquivo não existe."*

O desafio é desacoplar a camada de armazenamento da camada computacional, permitindo que as instâncias EC2 sejam efêmeras (descartáveis) sem perda de dados.

---

## 💡 A Solução: Armazenamento Desacoplado (EFS)

Este repositório implementa uma arquitetura de **Alta Disponibilidade (HA)** que resolve o problema de estado utilizando o **AWS Elastic File System (EFS)**.

Ao montar volumes EFS diretamente nos containers Docker via script de *Bootstrapping* (User Data), garantimos:

1. **Persistência Compartilhada:** O diretório `/wp-content` (uploads, temas, plugins) é único e compartilhado entre todas as instâncias em tempo real.
2. **Escalabilidade Elástica:** Novas instâncias lançadas pelo Auto Scaling Group visualizam imediatamente os arquivos existentes.
3. **Automação Total:** Toda a infraestrutura (Rede, Segurança, Storage, Compute) é provisionada via **Terraform**.

---

## 🛠 Componentes da Arquitetura (Implementados)

| Camada | Recurso | Descrição |
|--------|---------|-----------|
| **Entrada** | Application Load Balancer (ALB) | Recebe tráfego HTTP na porta 80. |
| **Roteamento** | Listener + Target Group | Listener encaminha para o target group; health check em `/`. |
| **Compute** | Auto Scaling Group (ASG) | Instâncias em **2 subnets** (2 AZs); min/max/desired configuráveis. |
| **Bootstrapping** | Launch Template + User Data | Instala Docker, monta EFS e sobe o `docker-compose.yml` do repositório. |
| **Containerização** | Docker + Docker Compose | WordPress e MySQL; compose versionado em `docker-compose.yml`. |
| **Storage** | EFS + 2 Mount Targets | Um mount target por subnet/AZ; `wp-content` e dados MySQL no EFS. |
| **Segurança** | Security Groups | ALB (80 público), EC2 (80 só do ALB + NFS 2049), EFS (2049 só da EC2). |

Fluxo: **Internet → ALB → Target Group → Instâncias do ASG (porta 80) → WordPress**. Todas as instâncias montam o mesmo EFS.

---

## 🚀 Como Executar

### Pré-requisitos

- Conta AWS ativa.
- Terraform instalado (ou **AWS CloudShell**).
- VPC com pelo menos **2 subnets públicas em AZs diferentes**.

### Passo a Passo

1. **Clone o repositório:**
   ```bash
   git clone https://github.com/seu-usuario/aws-wordpress-ha-efs-pattern.git
   cd aws-wordpress-ha-efs-pattern
   ```

2. **Configure as variáveis** (obrigatório: `vpc_id` e `public_subnets`):
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edite terraform.tfvars com os IDs da sua VPC e subnets.
   ```
   Para obter IDs da VPC padrão:
   ```bash
   aws ec2 describe-vpcs --query 'Vpcs[?IsDefault==`true`].VpcId' --output text
   aws ec2 describe-subnets --filters "Name=vpc-id,Values=<VPC_ID>" --query 'Subnets[*].SubnetId' --output text
   ```

3. **Provisione a infraestrutura:**
   ```bash
   terraform init
   terraform apply -auto-approve
   ```
   O Terraform criará: Security Groups, EFS (com 2 mount targets), ALB, listener, target group, launch template e **Auto Scaling Group**. O user data em cada instância instala Docker, monta o EFS e sobe o WordPress via `docker-compose.yml`.

4. **Acesse o WordPress:**
   Após o apply, use o output `alb_dns_name` no navegador:
   ```bash
   Outputs:
   alb_dns_name = "wordpress-alb-xxxxx.us-east-1.elb.amazonaws.com"
   alb_zone_id  = "Z35SXDOT..."
   ```
   Abra `http://<alb_dns_name>` e conclua a instalação do WordPress.

---

## 📂 Estrutura do Projeto

```text
.
├── main.tf                  # Security Groups, EFS, ALB, listener, target group, launch template, ASG
├── variables.tf             # Variáveis (VPC, subnets, instance_type, asg_min/max/desired)
├── outputs.tf               # alb_dns_name, alb_zone_id
├── terraform.tfvars.example  # Exemplo de variáveis (copie para terraform.tfvars)
├── docker-compose.yml       # WordPress + MySQL; conteúdo injetado nas instâncias via user data
├── .gitignore               # terraform.tfvars, .terraform/, *.tfstate, etc.
└── scripts/
    └── user_data.sh         # Bootstrap: Docker, mount EFS, escrita do compose e docker-compose up
```

---

## 🗺 Roadmap

| Fase | Status | Conteúdo |
|------|--------|----------|
| **Fase 1: Persistência & Compute** | ✅ Concluído | EFS, Docker, User Data, Security Groups. |
| **Parte 2: ALB completo** | ✅ Concluído | Listener (porta 80), target group, health check; tráfego do ALB até as instâncias. |
| **Parte 3: Auto Scaling** | ✅ Concluído | Launch template + ASG em 2 subnets; instâncias registradas no target group. |
| **Parte 4: EFS multi-AZ** | ✅ Concluído | Um mount target por subnet pública (EFS acessível em todas as AZs). |
| **Parte 5: Outputs** | ✅ Concluído | `alb_dns_name` e `alb_zone_id` para acesso e CNAME (Route 53). |
| **Parte 7: Compose versionado** | ✅ Concluído | `docker-compose.yml` no repositório; user data injeta o conteúdo nas instâncias. |
| **Fase 2: Performance & Edge** | 📋 Planejado | CloudFront na frente do ALB; AWS WAF. |
| **Fase 3: Banco gerenciado** | 📋 Planejado | Migração do MySQL em container para Amazon RDS (Multi-AZ). |

---

**Autor:** Rodolfo Martins | AWS Cloud Engineer
