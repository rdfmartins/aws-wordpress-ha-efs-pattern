# 💰 Monitoramento de Custos AWS

## 🔔 Configurar Alarme de Billing

Execute este comando **uma vez** para receber alertas quando os custos ultrapassarem $5/mês:

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name "Billing-Alert-5USD" \
  --alarm-description "Alerta quando custo passar de $5" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 21600 \
  --evaluation-periods 1 \
  --threshold 5.0 \
  --comparison-operator GreaterThanThreshold \
  --region us-east-1
```

**Nota:** Você precisa ter o SNS configurado para receber notificações por email.

---

## 📧 Configurar SNS para Notificações (Opcional)

Se quiser receber emails de alerta:

```bash
# 1. Criar tópico SNS
aws sns create-topic --name billing-alerts --region us-east-1

# 2. Inscrever seu email (substitua SEU_EMAIL)
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:$(aws sts get-caller-identity --query Account --output text):billing-alerts \
  --protocol email \
  --notification-endpoint SEU_EMAIL@example.com \
  --region us-east-1

# 3. Confirme o email que você vai receber

# 4. Atualizar o alarme para usar o SNS
aws cloudwatch put-metric-alarm \
  --alarm-name "Billing-Alert-5USD" \
  --alarm-description "Alerta quando custo passar de $5" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 21600 \
  --evaluation-periods 1 \
  --threshold 5.0 \
  --comparison-operator GreaterThanThreshold \
  --alarm-actions arn:aws:sns:us-east-1:$(aws sts get-caller-identity --query Account --output text):billing-alerts \
  --region us-east-1
```

---

## 🔍 Verificar Custos Manualmente

```bash
# Ver recursos que podem estar gerando custos
aws ec2 describe-instances --region us-east-1 --query 'Reservations[*].Instances[?State.Name==`running`].[InstanceId,InstanceType,LaunchTime]' --output table

aws elbv2 describe-load-balancers --region us-east-1 --query 'LoadBalancers[*].[LoadBalancerName,Type]' --output table

aws efs describe-file-systems --region us-east-1 --query 'FileSystems[*].[FileSystemId,Name,SizeInBytes.Value]' --output table

aws rds describe-db-instances --region us-east-1 --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceClass]' --output table

aws ec2 describe-nat-gateways --region us-east-1 --query 'NatGateways[?State==`available`].[NatGatewayId]' --output table

# Elastic IPs não associados (cobrados!)
aws ec2 describe-addresses --region us-east-1 --query 'Addresses[?AssociationId==null].[PublicIp]' --output table
```

---

## 💡 Dicas para Free Tier

### ✅ Recursos Gratuitos (com limites):
- **EC2:** 750h/mês de t2.micro ou t3.micro
- **EBS:** 30 GB de armazenamento
- **ALB:** Não está no free tier! (~$16/mês)
- **EFS:** 5 GB de armazenamento
- **RDS:** 750h/mês de db.t2.micro ou db.t3.micro + 20 GB

### ⚠️ Recursos que SEMPRE cobram:
- **NAT Gateway:** ~$32/mês + tráfego
- **Elastic IP não associado:** $0.005/hora (~$3.60/mês)
- **ALB:** ~$16/mês + tráfego
- **CloudFront:** Após free tier (50 GB/mês)

### 🎯 Recomendações:
1. Use **t3.micro** (free tier) ao invés de t3.small
2. Evite **ALB** em dev (use instância única com IP público)
3. Evite **NAT Gateway** (use subnets públicas)
4. Sempre rode `terraform destroy` após testes
5. Configure **alarmes de billing**

---

## 🧹 Limpeza Rápida

```bash
# Destruir toda a infraestrutura do projeto
cd /home/cloudshell-user/aws-wordpress-ha-efs-pattern
terraform destroy -auto-approve

# Verificar se ficou algo
aws ec2 describe-instances --region us-east-1 --filters "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].[InstanceId,InstanceType]' --output table
```

---

## 📊 Acessar Cost Explorer

Console AWS → Billing → Cost Explorer
- Veja custos por serviço
- Identifique picos de gasto
- Configure budgets
