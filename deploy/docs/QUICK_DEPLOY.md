# Quick Deploy - Delphi para Linux

Guia rápido para deploy. Para detalhes completos, veja [DEPLOY_LINUX_GUIDE.md](DEPLOY_LINUX_GUIDE.md)

## 🚀 Setup Inicial (Uma Vez)

### 1. No Servidor Linux

```bash
# Atualizar sistema
sudo apt-get update && sudo apt-get upgrade -y

# Instalar dependências
sudo apt-get install -y build-essential libc6-dev gcc-multilib g++-multilib libgcc-s1 libpq5 postgresql

# Configurar firewall
sudo ufw allow 22/tcp
sudo ufw allow 64211/tcp
sudo ufw allow 9000/tcp
sudo ufw enable

# Instalar PAServer
cd ~
tar -xzf PAServer-37.0.tar.gz
cd PAServer-37.0
chmod +x paserver
./paserver
# Definir senha: teamfees123
```

### 2. No Windows

```powershell
# Configurar SSH sem senha
ssh-keygen -t rsa -b 2048
type $env:USERPROFILE\.ssh\id_rsa.pub | ssh usuario@servidor "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# Copiar bibliotecas do sistema Linux
.\scripts\copy_sdk_libs.ps1

# Criar links simbólicos
.\scripts\create_lib_links.bat
```

### 3. No Delphi

1. Tools → Options → Connection Profile Manager
2. Add → Linux64
3. Host: SEU_IP, Port: 64211, Password: teamfees123
4. Test Connection
5. Project → Options → Target Platform: Linux64
6. Build

## 📦 Deploy (Toda Vez)

```powershell
# Executar script de deploy
.\scripts\deploy.ps1
```

Ou manualmente:

```powershell
# 1. Compilar no Delphi (Shift+F9)

# 2. Copiar binário
scp Linux64\Release\TeamFees usuario@servidor:/home/usuario/

# 3. Copiar .env
scp .env usuario@servidor:/home/usuario/

# 4. Reiniciar serviço
ssh usuario@servidor "sudo systemctl restart teamfees"
```

## 🔍 Comandos Úteis

```bash
# Ver status
sudo systemctl status teamfees

# Ver logs em tempo real
sudo journalctl -u teamfees -f

# Reiniciar
sudo systemctl restart teamfees

# Parar
sudo systemctl stop teamfees

# Testar manualmente
cd /home/usuario
export LD_LIBRARY_PATH=/home/usuario:$LD_LIBRARY_PATH
./TeamFees
```

## ⚠️ Problemas Comuns

| Erro | Solução |
|------|---------|
| `cannot find -lc` | Executar `copy_sdk_libs.ps1` e `create_lib_links.bat` |
| `Cannot load libpq.so` | `ln -sf /lib/x86_64-linux-gnu/libpq.so.5 ~/libpq.so` |
| `Connection refused` | Verificar firewall: `sudo ufw allow 64211/tcp` |
| Serviço não inicia | Ver logs: `sudo journalctl -u teamfees -n 50` |
