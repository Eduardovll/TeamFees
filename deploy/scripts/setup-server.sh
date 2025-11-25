#!/bin/bash
# ========================================
# Setup Completo - Oracle Cloud Ubuntu
# Backend Delphi + PostgreSQL
# ========================================

set -e  # Para na primeira falha

echo "🚀 Iniciando configuração do servidor..."

# ========================================
# 1. ATUALIZAR SISTEMA
# ========================================
echo ""
echo "📦 Atualizando sistema..."
sudo apt update
sudo apt upgrade -y

# ========================================
# 2. INSTALAR POSTGRESQL
# ========================================
echo ""
echo "🐘 Instalando PostgreSQL..."
sudo apt install postgresql postgresql-contrib -y

# Iniciar PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

echo "✅ PostgreSQL instalado!"

# ========================================
# 3. CONFIGURAR BANCO DE DADOS
# ========================================
echo ""
echo "🔧 Configurando banco de dados..."

# Criar usuário e banco
sudo -u postgres psql <<EOF
-- Criar usuário
CREATE USER teamfees WITH PASSWORD 'sua_senha_segura_aqui';

-- Criar banco
CREATE DATABASE teamfees_db OWNER teamfees;

-- Dar permissões
GRANT ALL PRIVILEGES ON DATABASE teamfees_db TO teamfees;

-- Conectar ao banco e dar permissões no schema
\c teamfees_db
GRANT ALL ON SCHEMA public TO teamfees;

\q
EOF

echo "✅ Banco de dados configurado!"

# ========================================
# 4. EXECUTAR MIGRATIONS (SQL)
# ========================================
echo ""
echo "📊 Executando migrations..."

# Você vai fazer upload dos arquivos SQL depois
# Por enquanto, cria a estrutura básica

sudo -u postgres psql -d teamfees_db <<EOF
-- Será executado quando você fizer upload dos arquivos .sql
-- Por enquanto, apenas confirma conexão
SELECT version();
EOF

echo "✅ Migrations prontas para execução!"

# ========================================
# 5. CRIAR DIRETÓRIO DA APLICAÇÃO
# ========================================
echo ""
echo "📁 Criando diretórios..."

sudo mkdir -p /opt/teamfees
sudo chown ubuntu:ubuntu /opt/teamfees
chmod 755 /opt/teamfees

echo "✅ Diretórios criados!"

# ========================================
# 6. INSTALAR DEPENDÊNCIAS
# ========================================
echo ""
echo "📚 Instalando dependências..."

# Bibliotecas necessárias para o executável Delphi
sudo apt install -y \
    libssl3 \
    libpq5 \
    libc6 \
    libstdc++6

echo "✅ Dependências instaladas!"

# ========================================
# 7. CONFIGURAR FIREWALL
# ========================================
echo ""
echo "🔥 Configurando firewall..."

sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 9000/tcp  # Backend (temporário, depois remove)
sudo ufw --force enable

echo "✅ Firewall configurado!"

# ========================================
# 8. CRIAR ARQUIVO .ENV
# ========================================
echo ""
echo "⚙️  Criando arquivo .env..."

cat > /opt/teamfees/.env <<EOF
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=teamfees_db
DB_USER=teamfees
DB_PASS=sua_senha_segura_aqui

# JWT
JWT_SECRET=$(openssl rand -base64 32)

# Server
HTTP_PORT=9000

# PIX Webhook
PIX_WEBHOOK_SECRET=$(openssl rand -base64 32)

# Mercado Pago
MERCADOPAGO_ACCESS_TOKEN=SEU_TOKEN_AQUI

# Twilio WhatsApp
TWILIO_ACCOUNT_SID=SEU_SID_AQUI
TWILIO_AUTH_TOKEN=SEU_TOKEN_AQUI
TWILIO_FROM_NUMBER=+14155238886

# Email (opcional)
SMTP_HOST=smtp-mail.outlook.com
SMTP_PORT=587
SMTP_USER=seu_email@hotmail.com
SMTP_PASSWORD=sua_senha
SMTP_FROM_EMAIL=seu_email@hotmail.com
SMTP_FROM_NAME=TeamFees

# Frontend URL
FRONTEND_URL=https://seu-frontend.vercel.app
EOF

chmod 600 /opt/teamfees/.env

echo "✅ Arquivo .env criado!"
echo "⚠️  IMPORTANTE: Edite /opt/teamfees/.env com suas credenciais!"

# ========================================
# 9. CRIAR SERVIÇO SYSTEMD
# ========================================
echo ""
echo "🔧 Criando serviço systemd..."

sudo tee /etc/systemd/system/teamfees.service > /dev/null <<EOF
[Unit]
Description=TeamFees Backend API
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/teamfees
ExecStart=/opt/teamfees/TeamFees
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable teamfees

echo "✅ Serviço criado!"

# ========================================
# 10. INSTALAR NGINX
# ========================================
echo ""
echo "🌐 Instalando Nginx..."

sudo apt install nginx -y

# Configurar reverse proxy
sudo tee /etc/nginx/sites-available/teamfees > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    # Aumentar timeout para operações longas
    proxy_connect_timeout 600;
    proxy_send_timeout 600;
    proxy_read_timeout 600;
    send_timeout 600;

    location / {
        proxy_pass http://localhost:9000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Ativar site
sudo ln -sf /etc/nginx/sites-available/teamfees /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

echo "✅ Nginx configurado!"

# ========================================
# 11. CONFIGURAR BACKUP AUTOMÁTICO
# ========================================
echo ""
echo "💾 Configurando backup automático..."

# Criar script de backup
sudo tee /opt/teamfees/backup.sh > /dev/null <<'EOF'
#!/bin/bash
BACKUP_DIR="/opt/teamfees/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup do banco
sudo -u postgres pg_dump teamfees_db | gzip > $BACKUP_DIR/db_$DATE.sql.gz

# Manter apenas últimos 7 dias
find $BACKUP_DIR -name "db_*.sql.gz" -mtime +7 -delete

echo "Backup criado: db_$DATE.sql.gz"
EOF

chmod +x /opt/teamfees/backup.sh

# Adicionar ao cron (diário às 3h)
(crontab -l 2>/dev/null; echo "0 3 * * * /opt/teamfees/backup.sh") | crontab -

echo "✅ Backup automático configurado!"

# ========================================
# 12. INSTALAR FERRAMENTAS DE MONITORAMENTO
# ========================================
echo ""
echo "📊 Instalando ferramentas de monitoramento..."

sudo apt install -y htop ncdu

echo "✅ Ferramentas instaladas!"

# ========================================
# RESUMO
# ========================================
echo ""
echo "=========================================="
echo "✨ CONFIGURAÇÃO CONCLUÍDA!"
echo "=========================================="
echo ""
echo "📋 Próximos passos:"
echo ""
echo "1. Editar credenciais:"
echo "   nano /opt/teamfees/.env"
echo ""
echo "2. Fazer upload das migrations SQL:"
echo "   scp db/*.sql ubuntu@SEU_IP:/opt/teamfees/"
echo "   psql -U teamfees -d teamfees_db -f /opt/teamfees/001_*.sql"
echo ""
echo "3. Fazer upload do executável:"
echo "   scp Linux64/Release/TeamFees ubuntu@SEU_IP:/opt/teamfees/"
echo "   sudo chmod +x /opt/teamfees/TeamFees"
echo ""
echo "4. Iniciar serviço:"
echo "   sudo systemctl start teamfees"
echo "   sudo systemctl status teamfees"
echo ""
echo "5. Ver logs:"
echo "   sudo journalctl -u teamfees -f"
echo ""
echo "=========================================="
echo "🎯 Servidor pronto para receber deploy!"
echo "=========================================="
