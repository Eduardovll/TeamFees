#!/bin/bash
set -e

echo "=== Configurando serviço TeamFees ==="

# Mover arquivo de serviço
sudo mv /home/administrator/teamfees.service /etc/systemd/system/

# Recarregar systemd
sudo systemctl daemon-reload

# Habilitar serviço para iniciar no boot
sudo systemctl enable teamfees

# Iniciar serviço
sudo systemctl start teamfees

# Aguardar 2 segundos
sleep 2

# Verificar status
sudo systemctl status teamfees --no-pager

# Liberar porta no firewall
sudo ufw allow 9000/tcp

echo ""
echo "=== Serviço configurado com sucesso! ==="
echo "API rodando em: http://204.12.218.78:9000"
echo ""
echo "Comandos úteis:"
echo "  sudo systemctl status teamfees   # Ver status"
echo "  sudo systemctl restart teamfees  # Reiniciar"
echo "  sudo systemctl stop teamfees     # Parar"
echo "  sudo journalctl -u teamfees -f   # Ver logs em tempo real"
