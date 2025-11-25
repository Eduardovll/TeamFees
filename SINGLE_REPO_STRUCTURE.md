# 📦 Estrutura Única de Repositório - TeamFees

## 🎯 **Decisão: Um Repositório Único**

Vamos usar apenas o repositório `TeamFees` com tudo organizado em pastas:

```
TeamFees/
├── src/                     # 💻 Código fonte Delphi
├── frontend/                # 🌐 Frontend React
├── database/                # 🗄️ Scripts SQL
├── deploy/                  # 🚀 Scripts de deploy
│   ├── scripts/
│   │   ├── windows/         # Scripts PowerShell/Batch
│   │   └── linux/           # Scripts Bash
│   ├── docs/                # Documentação de deploy
│   └── config/              # Configurações de servidor
├── docs/                    # 📚 Documentação geral
├── .github/                 # 🚀 CI/CD
├── .gitignore
├── README.md
└── TeamFees.dpr*
```

## 🔄 **Migrar Scripts de Deploy**

Vamos mover os scripts de `C:\TeamFees-Deploy` para dentro do repositório principal:

### Script de Migração:
```powershell
# Criar estrutura de deploy dentro do repo principal
mkdir C:\TeamFees-Clean\deploy
mkdir C:\TeamFees-Clean\deploy\scripts
mkdir C:\TeamFees-Clean\deploy\docs  
mkdir C:\TeamFees-Clean\deploy\config

# Mover scripts
robocopy C:\TeamFees-Deploy\scripts C:\TeamFees-Clean\deploy\scripts /E
robocopy C:\TeamFees-Deploy\docs C:\TeamFees-Clean\deploy\docs /E
robocopy C:\TeamFees-Deploy\config C:\TeamFees-Clean\deploy\config /E
```

## ✅ **Vantagens desta Estrutura**

### 🎯 **Simplicidade**
- Um único repositório para gerenciar
- Versionamento unificado
- Menos configuração de secrets

### 🔄 **Organização**
- Scripts organizados em `/deploy/`
- Separação clara por tipo de arquivo
- Fácil navegação

### 🚀 **CI/CD Simplificado**
- Scripts no mesmo repo
- Não precisa do `DEPLOY_TOKEN`
- Workflow mais direto

## 🛠️ **Workflow CI/CD Atualizado**

O workflow será mais simples, sem precisar acessar repositório externo:

```yaml
# Exemplo simplificado
- name: Deploy to server
  run: |
    chmod +x ./deploy/scripts/linux/deploy.sh
    ./deploy/scripts/linux/deploy.sh
```

## 📋 **Secrets Necessários (Reduzidos)**

Apenas estes secrets no repositório TeamFees:
- `SSH_PRIVATE_KEY`: Chave SSH para servidor
- `SERVER_HOST`: IP do servidor  
- `SERVER_USER`: Usuário do servidor
- `SLACK_WEBHOOK`: (Opcional) Notificações

**❌ Não precisa mais**: `DEPLOY_TOKEN`

## 🚀 **Próximos Passos**

1. **Migrar scripts** para dentro do repo principal
2. **Atualizar .gitignore** se necessário
3. **Simplificar workflow** CI/CD
4. **Fazer commit** da nova estrutura
5. **Testar pipeline** simplificado

---

**Resultado**: Estrutura mais simples e fácil de manter! 🎉