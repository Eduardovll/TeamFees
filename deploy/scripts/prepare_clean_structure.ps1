# 🚀 Script de Reorganização do Projeto TeamFees
# Separa código fonte dos scripts de deploy para estrutura Git limpa

param(
    [string]$SourcePath = "C:\TeamFees",
    [string]$CleanPath = "C:\TeamFees-Clean", 
    [string]$DeployPath = "C:\TeamFees-Deploy"
)

Write-Host "🚀 Iniciando reorganização do projeto TeamFees..." -ForegroundColor Green
Write-Host "📂 Origem: $SourcePath" -ForegroundColor Yellow
Write-Host "📦 Código Limpo: $CleanPath" -ForegroundColor Yellow  
Write-Host "🛠️ Scripts Deploy: $DeployPath" -ForegroundColor Yellow

# Criar estruturas base
Write-Host "`n📁 Criando estruturas de diretórios..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $CleanPath -Force | Out-Null
New-Item -ItemType Directory -Path $DeployPath -Force | Out-Null
New-Item -ItemType Directory -Path "$CleanPath\docs" -Force | Out-Null
New-Item -ItemType Directory -Path "$CleanPath\config" -Force | Out-Null
New-Item -ItemType Directory -Path "$CleanPath\tests" -Force | Out-Null
New-Item -ItemType Directory -Path "$DeployPath\docs" -Force | Out-Null
New-Item -ItemType Directory -Path "$DeployPath\config" -Force | Out-Null

# ✅ COPIAR CÓDIGO FONTE PARA REPOSITÓRIO LIMPO
Write-Host "`n💻 Copiando código fonte..." -ForegroundColor Cyan

# Código Delphi
if (Test-Path "$SourcePath\src") {
    robocopy "$SourcePath\src" "$CleanPath\src" /E /XD __history __recovery /NFL /NDL /NJH /NJS
    Write-Host "  ✅ Código Delphi copiado" -ForegroundColor Green
}

# Frontend React
if (Test-Path "$SourcePath\frontend") {
    robocopy "$SourcePath\frontend" "$CleanPath\frontend" /E /XD node_modules dist /NFL /NDL /NJH /NJS
    Write-Host "  ✅ Frontend React copiado" -ForegroundColor Green
}

# Database
if (Test-Path "$SourcePath\database") {
    robocopy "$SourcePath\database" "$CleanPath\database" /E /NFL /NDL /NJH /NJS
    Write-Host "  ✅ Scripts de database copiados" -ForegroundColor Green
}

# Arquivos do projeto Delphi
$projectFiles = @("TeamFees.dpr", "TeamFees.dproj", "boss.json", ".env.example")
foreach ($file in $projectFiles) {
    if (Test-Path "$SourcePath\$file") {
        Copy-Item "$SourcePath\$file" "$CleanPath\" -Force
        Write-Host "  ✅ $file copiado" -ForegroundColor Green
    }
}

# GitHub Actions
if (Test-Path "$SourcePath\.github") {
    robocopy "$SourcePath\.github" "$CleanPath\.github" /E /NFL /NDL /NJH /NJS
    Write-Host "  ✅ GitHub Actions copiado" -ForegroundColor Green
}

# Documentação de desenvolvimento (manter apenas algumas)
$devDocs = @("README.md", "ROTAS_API.md", "CONFIGURACAO.md")
foreach ($doc in $devDocs) {
    if (Test-Path "$SourcePath\$doc") {
        Copy-Item "$SourcePath\$doc" "$CleanPath\docs\" -Force
        Write-Host "  ✅ $doc copiado para docs/" -ForegroundColor Green
    }
}

# ⚠️ MOVER SCRIPTS DE DEPLOY PARA REPOSITÓRIO SEPARADO
Write-Host "`n🛠️ Movendo scripts de deploy..." -ForegroundColor Cyan

# Scripts organizados
if (Test-Path "$SourcePath\scripts") {
    robocopy "$SourcePath\scripts" "$DeployPath\scripts" /E /NFL /NDL /NJH /NJS
    Write-Host "  ✅ Scripts da pasta /scripts movidos" -ForegroundColor Green
}

# Scripts da raiz
$rootScripts = @("*.ps1", "*.bat", "*.sh")
foreach ($pattern in $rootScripts) {
    Get-ChildItem "$SourcePath\$pattern" -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Name -ne "prepare_clean_structure.ps1") {  # Não mover este script
            Copy-Item $_.FullName "$DeployPath\scripts\" -Force
            Write-Host "  ✅ $($_.Name) movido para deploy/scripts/" -ForegroundColor Green
        }
    }
}

# Documentação de deploy
$deployDocs = @("DEPLOY_LINUX_GUIDE.md", "QUICK_DEPLOY.md", "TIMELINE.md", "SERVER-SETUP-GUIDE.md", "PIPELINE-GUIDE.md")
foreach ($doc in $deployDocs) {
    if (Test-Path "$SourcePath\docs\$doc") {
        Copy-Item "$SourcePath\docs\$doc" "$DeployPath\docs\" -Force
        Write-Host "  ✅ $doc movido para deploy/docs/" -ForegroundColor Green
    } elseif (Test-Path "$SourcePath\$doc") {
        Copy-Item "$SourcePath\$doc" "$DeployPath\docs\" -Force
        Write-Host "  ✅ $doc movido para deploy/docs/" -ForegroundColor Green
    }
}

# Arquivos de configuração de servidor
$configFiles = @("teamfees.service")
foreach ($file in $configFiles) {
    if (Test-Path "$SourcePath\$file") {
        Copy-Item "$SourcePath\$file" "$DeployPath\config\" -Force
        Write-Host "  ✅ $file movido para deploy/config/" -ForegroundColor Green
    }
}

# 📝 CRIAR ARQUIVOS ESSENCIAIS
Write-Host "`n📝 Criando arquivos de configuração..." -ForegroundColor Cyan

# .gitignore para repositório limpo
$gitignoreContent = @"
# Delphi Build
__history/
__recovery/
*.identcache
*.dproj.local
*.~*
*.dsk
*.stat

# Build Outputs
Win32/
Win64/
Linux64/
*.exe
*.dll
*.so
*.dcu
*.o
*.rsm
*.map
*.tds

# Boss Dependencies
modules/

# Environment & Logs
.env
*.log
logs/

# Frontend
frontend/node_modules/
frontend/dist/
frontend/.env.local
frontend/.env.production

# IDE Files
.vscode/
.idea/
*.code-workspace

# OS Files
.DS_Store
Thumbs.db
desktop.ini

# Temporary Files
temp/
tmp/
*.tmp
*.bak
"@

Set-Content -Path "$CleanPath\.gitignore" -Value $gitignoreContent -Encoding UTF8
Write-Host "  ✅ .gitignore criado" -ForegroundColor Green

# README.md principal para repositório limpo
$readmeContent = @"
# 🏆 TeamFees - Sistema de Gestão de Mensalidades

Sistema completo para gestão de mensalidades de equipes esportivas, desenvolvido em Delphi com frontend React.

## 🚀 Tecnologias

- **Backend**: Delphi 12 + Horse Framework + PostgreSQL
- **Frontend**: React + TypeScript + Vite + Tailwind CSS
- **Deploy**: Linux Ubuntu Server + Systemd
- **CI/CD**: GitHub Actions

## 📦 Estrutura do Projeto

```
TeamFees/
├── src/                 # 💻 Backend Delphi
├── frontend/            # 🌐 Frontend React  
├── database/            # 🗄️ Scripts SQL
├── docs/                # 📚 Documentação
├── .github/             # 🚀 CI/CD
└── config/              # ⚙️ Configurações
```

## 🛠️ Desenvolvimento

### Pré-requisitos

- Delphi 12 ou superior
- Node.js 18+
- PostgreSQL 14+
- Boss Package Manager

### Setup Backend

```bash
# Instalar dependências
boss install

# Configurar ambiente
cp .env.example .env
# Editar .env com suas configurações

# Compilar
# Abrir TeamFees.dproj no Delphi e compilar (Shift+F9)
```

### Setup Frontend

```bash
cd frontend
npm install
npm run dev
```

## 🚀 Deploy

Para instruções de deploy, consulte o repositório separado:
**[TeamFees-Deploy](https://github.com/seu-usuario/TeamFees-Deploy)**

## 📚 Documentação

- [Rotas da API](docs/ROTAS_API.md)
- [Configuração](docs/CONFIGURACAO.md)
- [Documentação de Deploy](https://github.com/seu-usuario/TeamFees-Deploy)

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT.

---

**Desenvolvido por**: Eduardo Valle  
**Versão**: 1.0.0
"@

Set-Content -Path "$CleanPath\README.md" -Value $readmeContent -Encoding UTF8
Write-Host "  ✅ README.md principal criado" -ForegroundColor Green

# README.md para repositório de deploy
$deployReadmeContent = @"
# 🚀 TeamFees Deploy

Scripts e documentação para deploy do sistema TeamFees em ambiente Linux.

## 📁 Estrutura

```
TeamFees-Deploy/
├── scripts/             # 🛠️ Scripts de automação
│   ├── windows/         # Scripts PowerShell/Batch
│   └── linux/           # Scripts Bash
├── docs/                # 📚 Documentação de deploy
├── config/              # ⚙️ Configurações de servidor
└── README.md            # Este arquivo
```

## 🛠️ Scripts Disponíveis

### Windows (Desenvolvimento)

- **copy_sdk_libs.ps1**: Copia bibliotecas Linux para SDK Delphi
- **create_lib_links.bat**: Cria links simbólicos das bibliotecas
- **deploy.ps1**: Deploy automatizado completo

### Linux (Servidor)

- **setup_server.sh**: Configuração inicial do servidor
- **setup_service.sh**: Configuração do serviço systemd

## 📚 Documentação

- [Guia Completo de Deploy](docs/DEPLOY_LINUX_GUIDE.md)
- [Guia Rápido](docs/QUICK_DEPLOY.md)
- [Timeline do Projeto](docs/TIMELINE.md)
- [Setup do Servidor](docs/SERVER-SETUP-GUIDE.md)

## 🚀 Uso Rápido

### Setup Inicial (Uma Vez)

1. **No Servidor Linux**:
   ```bash
   ./scripts/linux/setup_server.sh
   ```

2. **No Windows (Delphi)**:
   ```powershell
   .\scripts\windows\copy_sdk_libs.ps1
   .\scripts\windows\create_lib_links.bat
   ```

### Deploy Regular

```powershell
.\scripts\windows\deploy.ps1
```

## 🔗 Repositório Principal

[TeamFees - Código Fonte](https://github.com/seu-usuario/TeamFees)

---

**Versão**: 1.0.0
"@

Set-Content -Path "$DeployPath\README.md" -Value $deployReadmeContent -Encoding UTF8
Write-Host "  ✅ README.md de deploy criado" -ForegroundColor Green

# 📊 RELATÓRIO FINAL
Write-Host "`n📊 Reorganização concluída!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

Write-Host "`n📦 REPOSITÓRIO PRINCIPAL (Código):" -ForegroundColor Yellow
Write-Host "   📂 $CleanPath" -ForegroundColor White
Write-Host "   ✅ Código fonte Delphi" -ForegroundColor Green
Write-Host "   ✅ Frontend React" -ForegroundColor Green  
Write-Host "   ✅ Scripts SQL" -ForegroundColor Green
Write-Host "   ✅ GitHub Actions" -ForegroundColor Green
Write-Host "   ✅ .gitignore configurado" -ForegroundColor Green

Write-Host "`n🛠️ REPOSITÓRIO DE DEPLOY:" -ForegroundColor Yellow
Write-Host "   📂 $DeployPath" -ForegroundColor White
Write-Host "   ✅ Scripts PowerShell/Bash" -ForegroundColor Green
Write-Host "   ✅ Documentação de deploy" -ForegroundColor Green
Write-Host "   ✅ Configurações de servidor" -ForegroundColor Green

Write-Host "`n🎯 PRÓXIMOS PASSOS:" -ForegroundColor Cyan
Write-Host "   1. cd $CleanPath" -ForegroundColor White
Write-Host "   2. git init" -ForegroundColor White
Write-Host "   3. git add ." -ForegroundColor White
Write-Host "   4. git commit -m 'Initial commit - clean structure'" -ForegroundColor White
Write-Host "   5. Criar repositório no GitHub" -ForegroundColor White
Write-Host "   6. git remote add origin <url>" -ForegroundColor White
Write-Host "   7. git push -u origin main" -ForegroundColor White

Write-Host "`n✨ Estrutura limpa e pronta para Git!" -ForegroundColor Green