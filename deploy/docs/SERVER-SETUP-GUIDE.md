# 🖥️ Guia Completo - Setup Servidor Oracle Cloud

## 📋 Arquitetura

```
┌─────────────────────────────────────┐
│     Oracle Cloud VM (Ubuntu)        │
│                                     │
│  ┌──────────────────────────────┐  │
│  │  PostgreSQL (localhost:5432) │  │
│  └──────────────────────────────┘  │
│              ↑                      │
│  ┌──────────────────────────────┐  │
│  │  Backend Delphi (port 9000)  │  │
│  └──────────────────────────────┘  │
│              ↑                      │
│  ┌──────────────────────────────┐  │
│  │  Nginx (port 80/443)         │  │
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
         ↑
    Internet
```

---

## 🚀 Passo a Passo Completo

### **1. Criar VM no Oracle Cloud**

1. Acesse: https://cloud.oracle.com
2. Compute → Instances → Create Instance
3. Configuração:
   - **Image:** Ubuntu 22.04
   - **Shape:** VM.Standard.A1.Flex (ARM - GRÁTIS)
   - **RAM:** 6GB (ou 12GB se usar 2 VMs)
   - **Storage:** 50GB
   - **Network:** Public IP
4. **Baixe a chave SSH** (oracle_key.pem)
5. Anote o **IP público**

---

### **2. Configurar SSH Local**

No seu Windows:

```powershell
# Criar pasta SSH
mkdir $env:USERPROFILE\.ssh

# Copiar chave baixada
copy Downloads\oracle_key.pem $env:USERPROFILE\.ssh\

# Ajustar permissões (PowerShell como Admin)
icacls "$env:USERPROFILE\.ssh\oracle_key.pem" /inheritance:r
icacls "$env:USERPROFILE\.ssh\oracle_key.pem" /grant:r "$env:USERNAME:(R)"
```

Testar conexão:
```powershell
ssh -i $env:USERPROFILE\.ssh\oracle_key.pem ubuntu@SEU_IP
```

---

### **3. Executar Setup Automático**

**Opção A: Upload e execução remota**

```powershell
# Upload do script
scp -i $env:USERPROFILE\.ssh\oracle_key.pem setup-server.sh ubuntu@SEU_IP:~/

# Executar
ssh -i $env:USERPROFILE\.ssh\oracle_key.pem ubuntu@SEU_IP "chmod +x setup-server.sh && ./setup-server.sh"
```

**Opção B: Copiar e colar no SSH**

1. Conecte via SSH
2. Crie o arquivo: `nano setup-server.sh`
3. Cole o conteúdo do script
4. Execute: `chmod +x setup-server.sh && ./setup-server.sh`

---

### **4. Configurar Credenciais**

Edite o arquivo .env no servidor:

```bash
ssh -i ~/.ssh/oracle_key.pem ubuntu@SEU_IP
nano /opt/teamfees/.env
```

Atualize:
```env
# Database
DB_PASS=SuaSenhaSuperSegura123!

# Mercado Pago
MERCADOPAGO_ACCESS_TOKEN=APP_USR-seu-token-aqui

# Twilio
TWILIO_ACCOUNT_SID=ACxxxxx
TWILIO_AUTH_TOKEN=xxxxx

# Frontend
FRONTEND_URL=https://seu-frontend.vercel.app
```

Salve: `Ctrl+O`, `Enter`, `Ctrl+X`

---

### **5. Deploy das Migrations**

**Do seu Windows:**

```powershell
# Edite o script com seu IP
notepad deploy-migrations.ps1

# Execute
.\deploy-migrations.ps1 -ServerIP "SEU_IP"
```

**Ou manualmente:**

```powershell
# Upload
scp -i ~/.ssh/oracle_key.pem db/*.sql ubuntu@SEU_IP:/opt/teamfees/

# Executar
ssh -i ~/.ssh/oracle_key.pem ubuntu@SEU_IP
cd /opt/teamfees
for file in *.sql; do
    PGPASSWORD='sua_senha' psql -U teamfees -d teamfees_db -f $file
done
```

---

### **6. Primeiro Deploy**

```powershell
# Execute o script de deploy
.\deploy.ps1
```

Ou manualmente:
```powershell
# Build
msbuild TeamFees.dproj /t:Build /p:Config=Release /p:Platform=Linux64

# Upload
scp -i ~/.ssh/oracle_key.pem Linux64/Release/TeamFees ubuntu@SEU_IP:/opt/teamfees/
scp -i ~/.ssh/oracle_key.pem Linux64/Release/*.so ubuntu@SEU_IP:/opt/teamfees/

# Permissões e start
ssh -i ~/.ssh/oracle_key.pem ubuntu@SEU_IP
sudo chmod +x /opt/teamfees/TeamFees
sudo systemctl start teamfees
sudo systemctl status teamfees
```

---

### **7. Verificar se está Rodando**

```bash
# Ver logs
sudo journalctl -u teamfees -f

# Status
sudo systemctl status teamfees

# Testar API
curl http://localhost:9000/health

# Ver processos
ps aux | grep TeamFees
```

---

### **8. Configurar SSL (Opcional mas Recomendado)**

**Se tiver domínio:**

```bash
# Instalar Certbot
sudo apt install certbot python3-certbot-nginx -y

# Obter certificado
sudo certbot --nginx -d seu-dominio.com

# Renovação automática já está configurada
```

**Se não tiver domínio:**
- Use o IP público: `http://SEU_IP`
- Ou use serviço gratuito: nip.io, sslip.io

---

## 🔧 Comandos Úteis

### **Gerenciar Serviço:**
```bash
sudo systemctl start teamfees    # Iniciar
sudo systemctl stop teamfees     # Parar
sudo systemctl restart teamfees  # Reiniciar
sudo systemctl status teamfees   # Status
```

### **Ver Logs:**
```bash
# Logs em tempo real
sudo journalctl -u teamfees -f

# Últimas 100 linhas
sudo journalctl -u teamfees -n 100

# Logs de hoje
sudo journalctl -u teamfees --since today
```

### **PostgreSQL:**
```bash
# Conectar ao banco
sudo -u postgres psql -d teamfees_db

# Backup manual
sudo -u postgres pg_dump teamfees_db > backup.sql

# Restaurar backup
sudo -u postgres psql -d teamfees_db < backup.sql

# Ver conexões ativas
sudo -u postgres psql -c "SELECT * FROM pg_stat_activity;"
```

### **Nginx:**
```bash
# Testar configuração
sudo nginx -t

# Recarregar
sudo systemctl reload nginx

# Ver logs de acesso
sudo tail -f /var/log/nginx/access.log

# Ver logs de erro
sudo tail -f /var/log/nginx/error.log
```

### **Monitoramento:**
```bash
# Uso de recursos
htop

# Espaço em disco
df -h

# Uso de disco por pasta
ncdu /opt/teamfees

# Portas abertas
sudo netstat -tulpn | grep LISTEN
```

---

## 🔐 Segurança

### **Firewall:**
```bash
# Ver regras
sudo ufw status

# Adicionar regra
sudo ufw allow 8080/tcp

# Remover regra
sudo ufw delete allow 8080/tcp
```

### **Atualizar Sistema:**
```bash
sudo apt update
sudo apt upgrade -y
sudo reboot  # Se necessário
```

### **Trocar Senha do Banco:**
```bash
sudo -u postgres psql
ALTER USER teamfees WITH PASSWORD 'nova_senha_super_segura';
\q

# Atualizar .env
nano /opt/teamfees/.env
```

---

## 📊 Monitoramento de Recursos

### **Uso Atual:**
```bash
# CPU e RAM
free -h
top

# Disco
df -h

# Rede
ifconfig
```

### **Limites Oracle Free Tier:**
- ✅ 2 VMs ARM (6GB RAM cada)
- ✅ 200GB storage total
- ✅ 10TB tráfego/mês
- ✅ GRÁTIS para sempre

---

## 🚨 Troubleshooting

### **Backend não inicia:**
```bash
# Ver erro específico
sudo journalctl -u teamfees -n 50

# Testar executável manualmente
cd /opt/teamfees
./TeamFees

# Verificar permissões
ls -la /opt/teamfees/TeamFees
```

### **Erro de conexão com banco:**
```bash
# Verificar se PostgreSQL está rodando
sudo systemctl status postgresql

# Testar conexão
PGPASSWORD='sua_senha' psql -U teamfees -d teamfees_db -h localhost

# Ver logs do PostgreSQL
sudo tail -f /var/log/postgresql/postgresql-*.log
```

### **Nginx não responde:**
```bash
# Verificar se está rodando
sudo systemctl status nginx

# Testar configuração
sudo nginx -t

# Ver logs
sudo tail -f /var/log/nginx/error.log
```

### **Porta 9000 já em uso:**
```bash
# Ver o que está usando
sudo lsof -i :9000

# Matar processo
sudo kill -9 PID
```

---

## 💾 Backup e Restore

### **Backup Completo:**
```bash
# Banco de dados
sudo -u postgres pg_dump teamfees_db | gzip > backup_$(date +%Y%m%d).sql.gz

# Arquivos da aplicação
tar -czf app_backup_$(date +%Y%m%d).tar.gz /opt/teamfees

# Download para seu PC
scp ubuntu@SEU_IP:~/backup_*.sql.gz .
```

### **Restore:**
```bash
# Upload backup
scp backup_20240101.sql.gz ubuntu@SEU_IP:~/

# Restaurar
gunzip backup_20240101.sql.gz
sudo -u postgres psql -d teamfees_db < backup_20240101.sql
```

---

## ✅ Checklist Final

- [ ] VM criada no Oracle Cloud
- [ ] SSH funcionando
- [ ] Setup script executado
- [ ] PostgreSQL rodando
- [ ] Migrations aplicadas
- [ ] .env configurado
- [ ] Backend deployado
- [ ] Serviço systemd ativo
- [ ] Nginx configurado
- [ ] Firewall configurado
- [ ] Backup automático ativo
- [ ] Logs sem erros
- [ ] API respondendo

---

## 🎯 Próximos Passos

1. ✅ Servidor configurado
2. ✅ Backend rodando
3. ⬜ Configurar domínio (opcional)
4. ⬜ Configurar SSL
5. ⬜ Deploy do frontend (Vercel)
6. ⬜ Configurar monitoramento
7. ⬜ Documentar API (Swagger)
