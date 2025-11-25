# Guia Completo: Deploy de Aplicação Delphi no Linux

Este guia documenta todo o processo de compilação cross-platform e deploy de uma aplicação Delphi (Windows) para Linux usando PAServer.

## 📋 Índice

1. [Pré-requisitos](#pré-requisitos)
2. [Configuração do Servidor Linux](#configuração-do-servidor-linux)
3. [Configuração do PAServer](#configuração-do-paserver)
4. [Configuração do Delphi IDE](#configuração-do-delphi-ide)
5. [Configuração do SDK Linux](#configuração-do-sdk-linux)
6. [Ajustes no Código](#ajustes-no-código)
7. [Compilação](#compilação)
8. [Deploy e Configuração do Serviço](#deploy-e-configuração-do-serviço)
9. [Scripts Úteis](#scripts-úteis)
10. [Troubleshooting](#troubleshooting)

---

## 🔧 Pré-requisitos

### Windows (Desenvolvimento)
- Delphi 12 Athens (ou superior)
- OpenSSH Client instalado
- Acesso SSH ao servidor Linux

### Linux (Produção)
- Ubuntu 22.04 LTS (ou similar)
- Acesso root/sudo
- PostgreSQL 14+ (se usar banco de dados)

---

## 🐧 Configuração do Servidor Linux

### 1. Atualizar Sistema

```bash
sudo apt-get update
sudo apt-get upgrade -y
```

### 2. Instalar Dependências Essenciais

```bash
# Ferramentas de compilação
sudo apt-get install -y build-essential gcc g++ make

# Bibliotecas de desenvolvimento
sudo apt-get install -y libc6-dev gcc-multilib g++-multilib libgcc-s1

# Cliente PostgreSQL (se necessário)
sudo apt-get install -y libpq5 libpq-dev

# PostgreSQL Server (se necessário)
sudo apt-get install -y postgresql postgresql-contrib
```

### 3. Configurar Firewall

```bash
# Habilitar firewall
sudo ufw enable

# Liberar SSH
sudo ufw allow 22/tcp

# Liberar porta da aplicação (exemplo: 9000)
sudo ufw allow 9000/tcp

# Liberar porta do PAServer
sudo ufw allow 64211/tcp

# Verificar status
sudo ufw status
```

---

## 🔌 Configuração do PAServer

### 1. Download e Instalação

```bash
# Fazer upload do PAServer-37.0.tar.gz para o servidor
# No Windows:
scp "C:\Program Files (x86)\Embarcadero\Studio\37.0\PAServer\PAServer-37.0.tar.gz" usuario@servidor:/home/usuario/

# No Linux:
cd /home/usuario
tar -xzf PAServer-37.0.tar.gz
cd PAServer-37.0
chmod +x paserver
```

### 2. Iniciar PAServer

```bash
# Iniciar manualmente (para teste)
./paserver

# Configurar senha quando solicitado
# Exemplo: teamfees123

# Porta padrão: 64211
```

### 3. Criar Serviço Systemd para PAServer (Opcional)

```bash
sudo nano /etc/systemd/system/paserver.service
```

Conteúdo:
```ini
[Unit]
Description=Embarcadero PAServer
After=network.target

[Service]
Type=simple
User=usuario
WorkingDirectory=/home/usuario/PAServer-37.0
ExecStart=/home/usuario/PAServer-37.0/paserver -password=teamfees123
Restart=always

[Install]
WantedBy=multi-user.target
```

Ativar:
```bash
sudo systemctl daemon-reload
sudo systemctl enable paserver
sudo systemctl start paserver
```

---

## 💻 Configuração do Delphi IDE

### 1. Habilitar Plataforma Linux64

No arquivo `.dproj`, adicionar:

```xml
<PropertyGroup>
    <Platform value="Linux64">True</Platform>
</PropertyGroup>
```

### 2. Criar Connection Profile

**Tools → Options → Connection Profile Manager**

- **Profile Name**: DatabaseMart (ou nome do seu servidor)
- **Platform**: Linux64
- **Host Name**: 204.12.218.78 (IP do servidor)
- **Port Number**: 64211
- **Password**: teamfees123 (senha do PAServer)
- **Test Connection**: Verificar se conecta

### 3. Configurar Projeto para Linux64

**Project → Options → Delphi Compiler**

- Selecionar **Target Platform**: Linux64
- Configurar **Search Path** se necessário

---

## 📚 Configuração do SDK Linux

### Problema Comum: Bibliotecas do Sistema Faltando

O Delphi precisa das bibliotecas do sistema Linux para linkar o executável. Por padrão, o SDK baixado via PAServer pode estar incompleto.

### Solução: Copiar Bibliotecas Manualmente

#### 1. Criar Estrutura de Diretórios no Windows

```cmd
mkdir "C:\Users\%USERNAME%\Documents\Embarcadero\Studio\SDKs\ubuntu22.04.sdk\lib\x86_64-linux-gnu"
```

#### 2. Script PowerShell para Copiar Bibliotecas

Salvar como `copy_sdk_libs.ps1`:

```powershell
$password = "SUA_SENHA_SSH"
$server = "usuario@servidor"
$libs = @(
    "libc.so.6",
    "libgcc_s.so.1",
    "libpthread.so.0",
    "libdl.so.2",
    "libm.so.6",
    "libz.so.1"
)

$destPath = "C:\Users\$env:USERNAME\Documents\Embarcadero\Studio\SDKs\ubuntu22.04.sdk\lib\x86_64-linux-gnu"

foreach ($lib in $libs) {
    Write-Host "Copiando $lib..."
    echo $password | scp -P 22 "${server}:/lib/x86_64-linux-gnu/$lib" "$destPath\"
}

Write-Host "Bibliotecas copiadas com sucesso!"
```

Executar:
```powershell
powershell -ExecutionPolicy Bypass -File copy_sdk_libs.ps1
```

#### 3. Criar Links Simbólicos (Versões sem Número)

```cmd
cd C:\Users\%USERNAME%\Documents\Embarcadero\Studio\SDKs\ubuntu22.04.sdk\lib\x86_64-linux-gnu

copy libc.so.6 libc.so
copy libdl.so.2 libdl.so
copy libpthread.so.0 libpthread.so
copy libm.so.6 libm.so
copy libz.so.1 libz.so
copy libgcc_s.so.1 libgcc_s.so
```

#### 4. Verificar Bibliotecas

```cmd
dir "C:\Users\%USERNAME%\Documents\Embarcadero\Studio\SDKs\ubuntu22.04.sdk\lib\x86_64-linux-gnu"
```

Deve listar:
```
libc.so
libc.so.6
libdl.so
libdl.so.2
libgcc_s.so
libgcc_s.so.1
libm.so
libm.so.6
libpthread.so
libpthread.so.0
libz.so
libz.so.1
```

---

## 🔨 Ajustes no Código

### 1. Código Cross-Platform (Windows/Linux)

Exemplo: `EnvLoader.pas`

```pascal
unit EnvLoader;

interface

uses
  System.SysUtils, System.Classes
  {$IFDEF MSWINDOWS}
  , Winapi.Windows
  {$ENDIF}
  {$IFDEF POSIX}
  , Posix.Stdlib
  {$ENDIF};

procedure LoadEnvFile(const FileName: string = '.env');

implementation

procedure LoadEnvFile(const FileName: string = '.env');
var
  EnvFile: TStringList;
  Line, Key, Value: string;
  EqualPos: Integer;
begin
  if not FileExists(FileName) then
  begin
    WriteLn('>>> Arquivo .env nao encontrado: ', ExpandFileName(FileName));
    Exit;
  end;

  EnvFile := TStringList.Create;
  try
    EnvFile.LoadFromFile(FileName);
    
    for Line in EnvFile do
    begin
      Line := Trim(Line);
      if (Line = '') or (Line.StartsWith('#')) then
        Continue;

      EqualPos := Pos('=', Line);
      if EqualPos > 0 then
      begin
        Key := Trim(Copy(Line, 1, EqualPos - 1));
        Value := Trim(Copy(Line, EqualPos + 1, Length(Line)));

        {$IFDEF MSWINDOWS}
        SetEnvironmentVariable(PChar(Key), PChar(Value));
        {$ENDIF}
        
        {$IFDEF POSIX}
        setenv(MarshaledAString(UTF8String(Key)), MarshaledAString(UTF8String(Value)), 1);
        {$ENDIF}
      end;
    end;
    
    WriteLn('>>> Arquivo .env carregado com sucesso!');
  finally
    EnvFile.Free;
  end;
end;

end.
```

### 2. Bibliotecas Compartilhadas no Linux

Para PostgreSQL (libpq.so):

```bash
# No servidor Linux, criar link simbólico
ln -sf /lib/x86_64-linux-gnu/libpq.so.5 /home/usuario/libpq.so

# Configurar LD_LIBRARY_PATH ao executar
export LD_LIBRARY_PATH=/home/usuario:$LD_LIBRARY_PATH
./SuaAplicacao
```

---

## 🚀 Compilação

### 1. No Delphi IDE

1. Selecionar **Target Platform**: Linux64
2. **Project → Build** (Shift+F9)
3. Aguardar compilação (pode demorar na primeira vez)

### 2. Localizar Binário

O executável estará em:
```
C:\SeuProjeto\Linux64\Release\SuaAplicacao
```

### 3. Copiar para Servidor

```cmd
scp C:\SeuProjeto\Linux64\Release\SuaAplicacao usuario@servidor:/home/usuario/
```

---

## 🎯 Deploy e Configuração do Serviço

### 1. Preparar Ambiente no Servidor

```bash
# Dar permissão de execução
chmod +x /home/usuario/SuaAplicacao

# Criar link para libpq (se necessário)
ln -sf /lib/x86_64-linux-gnu/libpq.so.5 /home/usuario/libpq.so

# Copiar arquivo .env
scp .env usuario@servidor:/home/usuario/
```

### 2. Testar Aplicação

```bash
cd /home/usuario
export LD_LIBRARY_PATH=/home/usuario:$LD_LIBRARY_PATH
./SuaAplicacao
```

### 3. Criar Serviço Systemd

Criar arquivo `/etc/systemd/system/suaaplicacao.service`:

```ini
[Unit]
Description=Sua Aplicacao API Server
After=network.target postgresql.service

[Service]
Type=simple
User=usuario
WorkingDirectory=/home/usuario
Environment="LD_LIBRARY_PATH=/home/usuario"
ExecStart=/home/usuario/SuaAplicacao
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### 4. Ativar Serviço

```bash
sudo systemctl daemon-reload
sudo systemctl enable suaaplicacao
sudo systemctl start suaaplicacao
sudo systemctl status suaaplicacao
```

### 5. Ver Logs

```bash
# Logs em tempo real
sudo journalctl -u suaaplicacao -f

# Últimas 50 linhas
sudo journalctl -u suaaplicacao -n 50
```

---

## 📝 Scripts Úteis

### Script de Deploy Completo

Salvar como `deploy.sh`:

```bash
#!/bin/bash
set -e

PROJECT_NAME="SuaAplicacao"
SERVER="usuario@servidor"
REMOTE_PATH="/home/usuario"
LOCAL_BIN="C:\SeuProjeto\Linux64\Release\$PROJECT_NAME"

echo "=== Iniciando Deploy ==="

# 1. Compilar no Windows (executar no Delphi)
echo "Compile o projeto no Delphi primeiro!"
read -p "Pressione Enter após compilar..."

# 2. Copiar binário
echo "Copiando binário..."
scp "$LOCAL_BIN" "$SERVER:$REMOTE_PATH/"

# 3. Copiar .env
echo "Copiando .env..."
scp .env "$SERVER:$REMOTE_PATH/"

# 4. Reiniciar serviço
echo "Reiniciando serviço..."
ssh "$SERVER" "sudo systemctl restart $PROJECT_NAME"

# 5. Verificar status
echo "Verificando status..."
ssh "$SERVER" "sudo systemctl status $PROJECT_NAME --no-pager"

echo "=== Deploy Concluído ==="
```

### Script de Configuração SSH sem Senha

Salvar como `setup_ssh_key.bat`:

```batch
@echo off
if not exist "%USERPROFILE%\.ssh\id_rsa" (
    ssh-keygen -t rsa -b 2048 -f "%USERPROFILE%\.ssh\id_rsa" -N ""
)
type "%USERPROFILE%\.ssh\id_rsa.pub" | ssh usuario@servidor "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && chmod 700 ~/.ssh"
echo Configuracao concluida!
pause
```

---

## 🔍 Troubleshooting

### Erro: "cannot find -lc" ou "cannot find -lgcc_s"

**Causa**: Bibliotecas do sistema Linux não estão no SDK local.

**Solução**: Seguir seção [Configuração do SDK Linux](#configuração-do-sdk-linux)

### Erro: "Cannot load vendor library [libpq.so]"

**Causa**: Biblioteca PostgreSQL não encontrada.

**Solução**:
```bash
# Instalar libpq
sudo apt-get install -y libpq5

# Criar link simbólico
ln -sf /lib/x86_64-linux-gnu/libpq.so.5 /home/usuario/libpq.so

# Configurar LD_LIBRARY_PATH no serviço systemd
Environment="LD_LIBRARY_PATH=/home/usuario"
```

### Erro: "Access Violation" ao executar no Linux

**Causa**: Incompatibilidade de bibliotecas ou código não thread-safe.

**Solução**:
1. Verificar se todas as bibliotecas estão presentes
2. Testar com `ldd ./SuaAplicacao` para ver dependências
3. Revisar código para compatibilidade POSIX

### Erro: "Connection refused" ao conectar no PAServer

**Causa**: Firewall bloqueando porta 64211.

**Solução**:
```bash
sudo ufw allow 64211/tcp
sudo ufw reload
```

### Aplicação não inicia como serviço

**Causa**: Permissões ou LD_LIBRARY_PATH incorreto.

**Solução**:
```bash
# Verificar permissões
chmod +x /home/usuario/SuaAplicacao

# Verificar logs
sudo journalctl -u suaaplicacao -n 50

# Testar manualmente
cd /home/usuario
export LD_LIBRARY_PATH=/home/usuario:$LD_LIBRARY_PATH
./SuaAplicacao
```

---

## 📊 Checklist de Deploy

- [ ] Servidor Linux atualizado
- [ ] Dependências instaladas (build-essential, libc6-dev, etc)
- [ ] PAServer instalado e rodando
- [ ] Firewall configurado (SSH, PAServer, Aplicação)
- [ ] Connection Profile criado no Delphi
- [ ] SDK Linux configurado com bibliotecas do sistema
- [ ] Código ajustado para cross-platform
- [ ] Projeto compila para Linux64 sem erros
- [ ] Binário copiado para servidor
- [ ] Arquivo .env copiado
- [ ] Banco de dados configurado
- [ ] Bibliotecas compartilhadas (libpq.so) configuradas
- [ ] Serviço systemd criado e ativado
- [ ] Aplicação iniciando corretamente
- [ ] Logs sem erros
- [ ] API respondendo nas portas corretas

---

## 🎓 Lições Aprendidas

1. **SDK Incompleto**: O PAServer nem sempre baixa todas as bibliotecas necessárias. Copiar manualmente é mais confiável.

2. **Links Simbólicos**: O linker procura por `libc.so`, mas o sistema tem `libc.so.6`. Criar cópias resolve no Windows.

3. **LD_LIBRARY_PATH**: Essencial configurar no serviço systemd para bibliotecas customizadas.

4. **Conditional Compilation**: Usar `{$IFDEF MSWINDOWS}` e `{$IFDEF POSIX}` para código específico de plataforma.

5. **Primeira Compilação**: Pode demorar bastante. Compilações subsequentes são mais rápidas.

6. **Logs**: `journalctl` é seu melhor amigo para debug no Linux.

---

## 📚 Referências

- [Embarcadero PAServer Documentation](https://docwiki.embarcadero.com/RADStudio/en/PAServer)
- [Delphi Linux Development](https://docwiki.embarcadero.com/RADStudio/en/Linux_Application_Development)
- [Systemd Service Files](https://www.freedesktop.org/software/systemd/man/systemd.service.html)

---

**Autor**: Eduardo Valle  
**Data**: Novembro 2025  
**Projeto**: TeamFees  
**Versão**: 1.0
