#!/bin/bash
# Script de configuração inicial do servidor Linux
# Executar no servidor: chmod +x setup_server.sh && ./setup_server.sh

set -e

echo "=== Configuração Inicial do Servidor Linux ==="
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar se é root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Execute como root ou com sudo${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/6] Atualizando sistema...${NC}"
apt-get update -qq
apt-get upgrade -y -qq

echo -e "${GREEN}OK${NC}"

echo -e "${YELLOW}[2/6] Instalando ferramentas de compilação...${NC}"
apt-get install -y -qq build-essential gcc g++ make

echo -e "${GREEN}OK${NC}"

echo -e "${YELLOW}[3/6] Instalando bibliotecas de desenvolvimento...${NC}"
apt-get install -y -qq libc6-dev gcc-multilib g++-multilib libgcc-s1

echo -e "${GREEN}OK${NC}"

echo -e "${YELLOW}[4/6] Instalando PostgreSQL...${NC}"
apt-get install -y -qq libpq5 libpq-dev postgresql postgresql-contrib

echo -e "${GREEN}OK${NC}"

echo -e "${YELLOW}[5/6] Configurando firewall...${NC}"
ufw --force enable
ufw allow 22/tcp
ufw allow 64211/tcp
ufw allow 9000/tcp
ufw reload

echo -e "${GREEN}OK${NC}"

echo -e "${YELLOW}[6/6] Configurando PostgreSQL...${NC}"
sudo -u postgres psql -c "CREATE USER teamfees WITH PASSWORD 'TeamFees@';" 2>/dev/null || echo "Usuário já existe"
sudo -u postgres psql -c "CREATE DATABASE teamfees_db OWNER teamfees;" 2>/dev/null || echo "Banco já existe"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE teamfees_db TO teamfees;" 2>/dev/null

echo -e "${GREEN}OK${NC}"

echo ""
echo -e "${GREEN}=== Configuração Concluída ===${NC}"
echo ""
echo "Próximos passos:"
echo "1. Instalar PAServer: tar -xzf PAServer-37.0.tar.gz && cd PAServer-37.0 && ./paserver"
echo "2. Configurar Connection Profile no Delphi"
echo "3. Compilar projeto para Linux64"
echo "4. Fazer deploy com deploy.ps1"
