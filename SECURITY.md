# 🔒 Segurança e Boas Práticas

## ⚠️ ANTES DE FAZER COMMIT

### 1. Verifique se `terraform.tfvars` NÃO está sendo commitado
```bash
git status
# terraform.tfvars deve aparecer como "untracked" ou não aparecer
```

### 2. Nunca commite:
- ❌ `terraform.tfvars` (contém IDs da sua VPC/subnets)
- ❌ `*.tfstate` (contém estado completo da infraestrutura)
- ❌ `.terraform/` (cache de providers)
- ❌ Senhas ou tokens em arquivos

### 3. Use o arquivo de exemplo
```bash
cp terraform.tfvars.example terraform.tfvars
# Edite terraform.tfvars com seus valores reais
```

---

## 🔐 Melhorias de Segurança para Produção

### 1. **Senha do MySQL**
Atualmente usa variável `db_password` (padrão: `changeme123`).

**Recomendado para produção:**
```terraform
# Use AWS Secrets Manager
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "wordpress/db-password"
}

# Ou AWS Systems Manager Parameter Store
data "aws_ssm_parameter" "db_password" {
  name = "/wordpress/db-password"
}
```

### 2. **RDS ao invés de MySQL em container**
- Multi-AZ automático
- Backups gerenciados
- Patches automáticos
- Melhor performance

### 3. **HTTPS no ALB**
- Adicione certificado SSL/TLS (ACM)
- Redirecione HTTP → HTTPS
- Use Route 53 para domínio customizado

### 4. **WAF (Web Application Firewall)**
- Proteção contra SQL injection
- Rate limiting
- Bloqueio de IPs maliciosos

---

## 📋 Checklist Antes do Push

- [ ] `terraform.tfvars` está no `.gitignore`
- [ ] Nenhum arquivo `.tfstate` será commitado
- [ ] Senha padrão foi alterada em produção
- [ ] README atualizado com instruções claras
- [ ] `terraform.tfvars.example` tem valores de exemplo (não reais)

---

## 🚀 Deploy Seguro

```bash
# 1. Clone o repositório
git clone <seu-repo>
cd aws-wordpress-ha-efs-pattern

# 2. Copie e configure variáveis
cp terraform.tfvars.example terraform.tfvars
# Edite terraform.tfvars com seus valores

# 3. MUDE A SENHA DO BANCO!
# Em terraform.tfvars:
db_password = "SuaSenhaForteAqui123!"

# 4. Deploy
terraform init
terraform plan
terraform apply
```
