# 🚀 Guia Completo - Configuração GitHub + CI/CD

## 📋 Passo a Passo Completo

### 1️⃣ **Criar Repositórios no GitHub**

#### Repositório Principal (TeamFees)
1. Acesse: https://github.com/new
2. Configure:
   - **Repository name**: `TeamFees`
   - **Description**: `Sistema de gestão de mensalidades - Delphi + React`
   - **Visibility**: `Private` (recomendado)
   - **❌ NÃO marque**: "Add a README file"
   - **❌ NÃO marque**: "Add .gitignore"
   - **❌ NÃO marque**: "Choose a license"

3. Clique em **"Create repository"**

#### Repositório de Deploy (TeamFees-Deploy)
1. Acesse novamente: https://github.com/new
2. Configure:
   - **Repository name**: `TeamFees-Deploy`
   - **Description**: `Scripts e documentação de deploy para TeamFees`
   - **Visibility**: `Private`
   - **❌ NÃO marque nenhuma opção**

3. Clique em **"Create repository"**

### 2️⃣ **Conectar Repositório Principal**

Abra o terminal/PowerShell na pasta `C:\TeamFees-Clean` e execute:

```bash
# Adicionar remote (substitua SEU-USUARIO pelo seu username do GitHub)
git remote add origin https://github.com/SEU-USUARIO/TeamFees.git

# Renomear branch para main
git branch -M main

# Fazer push inicial
git push -u origin main
```

### 3️⃣ **Conectar Repositório de Deploy**

Abra o terminal/PowerShell na pasta `C:\TeamFees-Deploy` e execute:

```bash
# Inicializar Git
git init

# Adicionar todos os arquivos
git add .

# Fazer commit inicial
git commit -m "Initial commit - deploy scripts and documentation"

# Adicionar remote (substitua SEU-USUARIO)
git remote add origin https://github.com/SEU-USUARIO/TeamFees-Deploy.git

# Renomear branch para main
git branch -M main

# Fazer push inicial
git push -u origin main
```

### 4️⃣ **Configurar Secrets no GitHub**

#### No repositório TeamFees:

1. Acesse: `https://github.com/SEU-USUARIO/TeamFees/settings/secrets/actions`
2. Clique em **"New repository secret"**
3. Adicione cada secret abaixo:

**DEPLOY_TOKEN** (Token para acessar TeamFees-Deploy):
- Name: `DEPLOY_TOKEN`
- Value: [Vamos criar na próxima etapa]

**SSH_PRIVATE_KEY** (Chave SSH para servidor):
- Name: `SSH_PRIVATE_KEY`
- Value: [Sua chave SSH privada]

**SERVER_HOST** (IP do servidor):
- Name: `SERVER_HOST`
- Value: `SEU_IP_DO_SERVIDOR`

**SERVER_USER** (Usuário do servidor):
- Name: `SERVER_USER`
- Value: `administrator` (ou seu usuário)

**SLACK_WEBHOOK** (Opcional - notificações):
- Name: `SLACK_WEBHOOK`
- Value: [URL do webhook do Slack]

### 5️⃣ **Criar Token de Deploy**

1. Acesse: https://github.com/settings/tokens
2. Clique em **"Generate new token"** → **"Generate new token (classic)"**
3. Configure:
   - **Note**: `TeamFees Deploy Token`
   - **Expiration**: `No expiration` (ou 1 ano)
   - **Scopes**: Marque apenas `repo` (Full control of private repositories)
4. Clique em **"Generate token"**
5. **COPIE O TOKEN** (só aparece uma vez!)
6. Volte aos secrets do TeamFees e adicione como `DEPLOY_TOKEN`

### 6️⃣ **Configurar Chave SSH (se não tiver)**

#### No Windows (PowerShell):
```powershell
# Gerar chave SSH (se não tiver)
ssh-keygen -t rsa -b 4096 -C "seu-email@exemplo.com"

# Copiar chave pública para servidor
type $env:USERPROFILE\.ssh\id_rsa.pub | ssh usuario@servidor "cat >> ~/.ssh/authorized_keys"

# Copiar chave privada para usar no GitHub
Get-Content $env:USERPROFILE\.ssh\id_rsa | clip
```

#### Adicionar chave privada no GitHub:
1. Cole o conteúdo copiado no secret `SSH_PRIVATE_KEY`

### 7️⃣ **Testar Configuração**

#### Teste 1: Push no repositório principal
```bash
cd C:\TeamFees-Clean
echo "# Test" >> README.md
git add README.md
git commit -m "Test CI/CD trigger"
git push
```

#### Teste 2: Verificar Actions
1. Acesse: `https://github.com/SEU-USUARIO/TeamFees/actions`
2. Deve aparecer o workflow rodando

### 8️⃣ **Configurações Opcionais**

#### Proteção da Branch Main:
1. Acesse: `https://github.com/SEU-USUARIO/TeamFees/settings/branches`
2. Clique em **"Add rule"**
3. Configure:
   - **Branch name pattern**: `main`
   - ✅ **Require status checks to pass**
   - ✅ **Require branches to be up to date**
   - ✅ **Require pull request reviews**

#### Notificações Slack (Opcional):
1. No Slack: `/apps` → Buscar "Incoming Webhooks"
2. Configurar webhook para seu canal
3. Copiar URL e adicionar no secret `SLACK_WEBHOOK`

## 🔧 **Comandos de Referência Rápida**

### Comandos Git Essenciais:
```bash
# Status do repositório
git status

# Adicionar mudanças
git add .

# Commit
git commit -m "Sua mensagem"

# Push
git push

# Pull (buscar atualizações)
git pull

# Ver histórico
git log --oneline

# Criar nova branch
git checkout -b nova-feature

# Trocar de branch
git checkout main
```

### Comandos para Deploy Manual:
```bash
# Compilar no Delphi (Shift+F9)
# Depois executar:
cd C:\TeamFees-Deploy
.\scripts\deploy.ps1
```

## 🐛 **Troubleshooting**

### Erro: "Permission denied (publickey)"
```bash
# Testar conexão SSH
ssh -T git@github.com

# Se falhar, verificar chave SSH
ssh-add -l
```

### Erro: "remote: Repository not found"
```bash
# Verificar remote
git remote -v

# Corrigir remote
git remote set-url origin https://github.com/SEU-USUARIO/TeamFees.git
```

### Erro no CI/CD: "Delphi not found"
- Verificar se o workflow está usando a versão correta do Delphi
- Pode precisar ajustar para usar self-hosted runner

## 📞 **Próximos Passos**

1. ✅ Criar repositórios no GitHub
2. ✅ Configurar secrets
3. ✅ Testar primeiro push
4. ✅ Verificar se CI/CD roda
5. ✅ Fazer primeiro deploy automático

---

**Dúvidas?** Siga este guia passo a passo e me avise se encontrar algum problema!