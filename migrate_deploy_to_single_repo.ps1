# Script para migrar deploy para repositório único
param(
    [string]$CleanPath = "C:\TeamFees-Clean",
    [string]$DeployPath = "C:\TeamFees-Deploy"
)

Write-Host "🔄 Migrando scripts de deploy para repositório único..." -ForegroundColor Green

# Verificar se estamos na pasta correta
if (!(Test-Path "$CleanPath\TeamFees.dpr")) {
    Write-Host "❌ Pasta TeamFees-Clean não encontrada em: $CleanPath" -ForegroundColor Red
    exit 1
}

# Verificar se pasta de deploy existe
if (!(Test-Path $DeployPath)) {
    Write-Host "❌ Pasta TeamFees-Deploy não encontrada em: $DeployPath" -ForegroundColor Red
    exit 1
}

# Criar estrutura de deploy dentro do repo principal
Write-Host "📁 Criando estrutura de deploy..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path "$CleanPath\deploy" -Force | Out-Null
New-Item -ItemType Directory -Path "$CleanPath\deploy\scripts" -Force | Out-Null
New-Item -ItemType Directory -Path "$CleanPath\deploy\docs" -Force | Out-Null
New-Item -ItemType Directory -Path "$CleanPath\deploy\config" -Force | Out-Null

# Mover scripts
Write-Host "🛠️ Movendo scripts..." -ForegroundColor Cyan
if (Test-Path "$DeployPath\scripts") {
    robocopy "$DeployPath\scripts" "$CleanPath\deploy\scripts" /E /NFL /NDL /NJH /NJS
    Write-Host "  ✅ Scripts movidos" -ForegroundColor Green
}

# Mover documentação
Write-Host "📚 Movendo documentação..." -ForegroundColor Cyan
if (Test-Path "$DeployPath\docs") {
    robocopy "$DeployPath\docs" "$CleanPath\deploy\docs" /E /NFL /NDL /NJH /NJS
    Write-Host "  ✅ Documentação movida" -ForegroundColor Green
}

# Mover configurações
Write-Host "⚙️ Movendo configurações..." -ForegroundColor Cyan
if (Test-Path "$DeployPath\config") {
    robocopy "$DeployPath\config" "$CleanPath\deploy\config" /E /NFL /NDL /NJH /NJS
    Write-Host "  ✅ Configurações movidas" -ForegroundColor Green
}

# Mover README do deploy
if (Test-Path "$DeployPath\README.md") {
    Copy-Item "$DeployPath\README.md" "$CleanPath\deploy\README.md" -Force
    Write-Host "  ✅ README de deploy movido" -ForegroundColor Green
}

# Atualizar .gitignore se necessário
Write-Host "📝 Atualizando .gitignore..." -ForegroundColor Cyan
$gitignorePath = "$CleanPath\.gitignore"
$gitignoreContent = Get-Content $gitignorePath -Raw

# Adicionar exclusões específicas para deploy se não existirem
$deployExclusions = @"

# Deploy específico
deploy/scripts/*.log
deploy/temp/
"@

if ($gitignoreContent -notmatch "deploy/scripts/\*\.log") {
    Add-Content -Path $gitignorePath -Value $deployExclusions
    Write-Host "  ✅ .gitignore atualizado" -ForegroundColor Green
}

# Criar estrutura de pastas organizadas
Write-Host "📂 Organizando scripts por plataforma..." -ForegroundColor Cyan

# Criar subpastas se não existirem
New-Item -ItemType Directory -Path "$CleanPath\deploy\scripts\windows" -Force | Out-Null
New-Item -ItemType Directory -Path "$CleanPath\deploy\scripts\linux" -Force | Out-Null

# Mover scripts para pastas corretas
$windowsScripts = Get-ChildItem "$CleanPath\deploy\scripts\*.ps1", "$CleanPath\deploy\scripts\*.bat" -ErrorAction SilentlyContinue
foreach ($script in $windowsScripts) {
    if ($script.Directory.Name -ne "windows") {
        Move-Item $script.FullName "$CleanPath\deploy\scripts\windows\" -Force
        Write-Host "  📁 $($script.Name) → windows/" -ForegroundColor Gray
    }
}

$linuxScripts = Get-ChildItem "$CleanPath\deploy\scripts\*.sh" -ErrorAction SilentlyContinue
foreach ($script in $linuxScripts) {
    if ($script.Directory.Name -ne "linux") {
        Move-Item $script.FullName "$CleanPath\deploy\scripts\linux\" -Force
        Write-Host "  📁 $($script.Name) → linux/" -ForegroundColor Gray
    }
}

# Atualizar README principal
Write-Host "📖 Atualizando README principal..." -ForegroundColor Cyan
$readmePath = "$CleanPath\README.md"
$readmeContent = Get-Content $readmePath -Raw

# Atualizar seção de deploy no README
$newDeploySection = @"

## 🚀 Deploy

Scripts de deploy estão organizados na pasta `deploy/`:

- **Windows**: `deploy/scripts/windows/`
- **Linux**: `deploy/scripts/linux/`
- **Docs**: `deploy/docs/`
- **Config**: `deploy/config/`

### Deploy Rápido
```bash
# Compilar no Delphi (Shift+F9)
# Executar deploy
.\deploy\scripts\windows\deploy.ps1
```

Para documentação completa, veja: [Deploy Guide](deploy/docs/DEPLOY_LINUX_GUIDE.md)
"@

# Substituir seção de deploy se existir, senão adicionar
if ($readmeContent -match "## 🚀 Deploy") {
    $readmeContent = $readmeContent -replace "## 🚀 Deploy.*?(?=##|$)", $newDeploySection
} else {
    $readmeContent += $newDeploySection
}

Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
Write-Host "  ✅ README atualizado" -ForegroundColor Green

# Adicionar mudanças ao Git
Write-Host "📝 Adicionando ao Git..." -ForegroundColor Cyan
Push-Location $CleanPath
try {
    git add .
    git status --porcelain
    Write-Host "  ✅ Arquivos adicionados ao Git" -ForegroundColor Green
    
    Write-Host "`n📋 Para fazer commit:" -ForegroundColor Yellow
    Write-Host "   git commit -m 'Migrate deploy scripts to single repository'" -ForegroundColor White
    Write-Host "   git push" -ForegroundColor White
} catch {
    Write-Host "  ⚠️ Erro ao adicionar ao Git" -ForegroundColor Yellow
} finally {
    Pop-Location
}

# Relatório final
Write-Host "`n📊 Migração concluída!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

Write-Host "`n📁 Nova estrutura:" -ForegroundColor Yellow
Write-Host "   TeamFees/" -ForegroundColor White
Write-Host "   ├── deploy/" -ForegroundColor White
Write-Host "   │   ├── scripts/windows/" -ForegroundColor White
Write-Host "   │   ├── scripts/linux/" -ForegroundColor White
Write-Host "   │   ├── docs/" -ForegroundColor White
Write-Host "   │   └── config/" -ForegroundColor White
Write-Host "   ├── src/" -ForegroundColor White
Write-Host "   ├── frontend/" -ForegroundColor White
Write-Host "   └── ..." -ForegroundColor White

Write-Host "`n🎯 Próximos passos:" -ForegroundColor Cyan
Write-Host "   1. Fazer commit das mudanças" -ForegroundColor White
Write-Host "   2. Criar apenas o repositório 'TeamFees' no GitHub" -ForegroundColor White
Write-Host "   3. Configurar secrets simplificados (sem DEPLOY_TOKEN)" -ForegroundColor White
Write-Host "   4. Testar pipeline CI/CD" -ForegroundColor White

Write-Host "`n✨ Agora você tem tudo em um repositório único!" -ForegroundColor Green