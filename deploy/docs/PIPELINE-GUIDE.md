# 🚀 Guia de Pipeline CI/CD - TeamFees

## 📋 Opções de Deploy Automatizado

---

## **Opção 1: Script PowerShell Local** ⭐ Mais Simples

### **Como usar:**

1. **Configure o script `deploy.ps1`:**
```powershell
$ServerIP = "123.456.789.0"  # IP do Oracle Cloud
$ServerUser = "ubuntu"
$SSHKey = "$env:USERPROFILE\.ssh\oracle_key.pem"
```

2. **Execute:**
```powershell
.\deploy.ps1
```

### **O que faz:**
1. ✅ Compila projeto para Linux64
2. ✅ Cria backup no servidor
3. ✅ Envia executável via SCP
4. ✅ Reinicia serviço
5. ✅ Verifica se está rodando
6. ✅ Mostra logs

### **Tempo:** ~2 minutos

---

## **Opção 2: GitHub Actions** 🤖 Automático

### **Como configurar:**

1. **Adicione secrets no GitHub:**
   - Settings → Secrets → Actions
   - `SSH_PRIVATE_KEY`: Conteúdo da chave SSH
   - `SERVER_IP`: IP do servidor Oracle

2. **Faça commit e push:**
```bash
git add .
git commit -m "Deploy automático"
git push origin main
```

3. **Pronto!** Deploy automático a cada push.

### **O que faz:**
- ✅ Detecta push na branch main
- ✅ Compila automaticamente
- ✅ Deploy automático
- ✅ Notifica se falhar

---

## **Opção 3: Deploy Manual Rápido**

### **Comando único:**
```powershell
# Build
msbuild TeamFees.dproj /t:Build /p:Config=Release /p:Platform=Linux64

# Deploy
scp -i ~/.ssh/oracle_key.pem Linux64/Release/TeamFees ubuntu@SEU_IP:/opt/teamfees/
ssh -i ~/.ssh/oracle_key.pem ubuntu@SEU_IP "sudo systemctl restart teamfees"
```

---

## 🔧 **Configuração Inicial do Servidor**

### **1. Criar serviço systemd:**

SSH no servidor:
```bash
ssh -i ~/.ssh/oracle_key.pem ubuntu@SEU_IP
```

Criar arquivo de serviço:
```bash
sudo nano /etc/systemd/system/teamfees.service
```

Conteúdo:
```ini
[Unit]
Description=TeamFees Backend API
After=network.target postgresql.service

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/teamfees
ExecStart=/opt/teamfees/TeamFees
Restart=always
RestartSec=10
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

[Install]
WantedBy=multi-user.target
```

Ativar serviço:
```bash
sudo systemctl daemon-reload
sudo systemctl enable teamfees
sudo systemctl start teamfees
```

### **2. Configurar Nginx (reverse proxy):**

```bash
sudo apt install nginx -y
sudo nano /etc/nginx/sites-available/teamfees
```

Conteúdo:
```nginx
server {
    listen 80;
    server_name seu-dominio.com;

    location / {
        proxy_pass http://localhost:9000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Ativar:
```bash
sudo ln -s /etc/nginx/sites-available/teamfees /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### **3. SSL com Let's Encrypt:**

```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d seu-dominio.com
```

---

## 📊 **Fluxo da Pipeline**

```
┌─────────────────┐
│  1. Código      │
│  (Windows)      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  2. Build       │
│  (Delphi)       │
│  Linux64        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  3. Backup      │
│  (Servidor)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  4. Upload      │
│  (SCP/SSH)      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  5. Restart     │
│  (systemd)      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  6. Health      │
│  Check          │
└─────────────────┘
```

---

## 🎯 **Comandos Úteis**

### **Ver logs:**
```bash
ssh ubuntu@SEU_IP "sudo journalctl -u teamfees -f"
```

### **Status do serviço:**
```bash
ssh ubuntu@SEU_IP "sudo systemctl status teamfees"
```

### **Rollback (voltar versão):**
```bash
ssh ubuntu@SEU_IP "sudo cp /opt/teamfees/TeamFees.backup.YYYYMMDD_HHMMSS /opt/teamfees/TeamFees && sudo systemctl restart teamfees"
```

### **Limpar backups antigos:**
```bash
ssh ubuntu@SEU_IP "sudo find /opt/teamfees -name 'TeamFees.backup.*' -mtime +7 -delete"
```

---

## ✅ **Checklist de Deploy**

- [ ] Código compilando sem erros
- [ ] Testes passando
- [ ] .env.production configurado
- [ ] SSH key configurada
- [ ] Servidor acessível
- [ ] PostgreSQL rodando
- [ ] Backup criado
- [ ] Deploy executado
- [ ] Health check OK
- [ ] Logs sem erros

---

## 🚨 **Troubleshooting**

### **Erro: Permission denied**
```bash
ssh ubuntu@SEU_IP "sudo chmod +x /opt/teamfees/TeamFees"
```

### **Erro: Port already in use**
```bash
ssh ubuntu@SEU_IP "sudo lsof -i :9000"
ssh ubuntu@SEU_IP "sudo systemctl restart teamfees"
```

### **Erro: Database connection**
```bash
ssh ubuntu@SEU_IP "sudo systemctl status postgresql"
```

---

## 💡 **Dicas**

1. **Sempre teste localmente antes de fazer deploy**
2. **Mantenha backups automáticos do banco**
3. **Use tags Git para versionar releases**
4. **Configure alertas de erro (Sentry, etc)**
5. **Monitore uso de recursos (htop, netdata)**

---

## 📈 **Próximos Passos**

1. ✅ Deploy manual funcionando
2. ✅ Script PowerShell automatizado
3. ⬜ GitHub Actions (opcional)
4. ⬜ Monitoramento (Grafana)
5. ⬜ Backup automático do banco
6. ⬜ Blue-Green deployment
