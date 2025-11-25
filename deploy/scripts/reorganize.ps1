# Script de Reorganização TeamFees
param(
    [string]$SourcePath = "C:\TeamFees",
    [string]$CleanPath = "C:\TeamFees-Clean", 
    [string]$DeployPath = "C:\TeamFees-Deploy"
)

Write-Host "🚀 Iniciando reorganização do projeto TeamFees..." -ForegroundColor Green

# Criar estruturas base
Write-Host "📁 Criando estruturas..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $CleanPath -Force | Out-Null
New-Item -ItemType Directory -Path $DeployPath -Force | Out-Null
New-Item -ItemType Directory -Path "$CleanPath\docs" -Force | Out-Null
New-Item -ItemType Directory -Path "$CleanPath\config" -Force | Out-Null
New-Item -ItemType Directory -Path "$DeployPath\docs" -Force | Out-Null
New-Item -ItemType Directory -Path "$DeployPath\config" -Force | Out-Null

# Copiar código fonte
Write-Host "💻 Copiando código fonte..." -ForegroundColor Cyan

if (Test-Path "$SourcePath\src") {
    robocopy "$SourcePath\src" "$CleanPath\src" /E /XD __history __recovery /NFL /NDL /NJH /NJS
    Write-Host "  ✅ Código Delphi copiado" -ForegroundColor Green
}

if (Test-Path "$SourcePath\frontend") {
    robocopy "$SourcePath\frontend" "$CleanPath\frontend" /E /XD node_modules dist /NFL /NDL /NJH /NJS
    Write-Host "  ✅ Frontend React copiado" -ForegroundColor Green
}

if (Test-Path "$SourcePath\database") {
    robocopy "$SourcePath\database" "$CleanPath\database" /E /NFL /NDL /NJH /NJS
    Write-Host "  ✅ Scripts de database copiados" -ForegroundColor Green
}

# Arquivos do projeto
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

# Mover scripts de deploy
Write-Host "🛠️ Movendo scripts de deploy..." -ForegroundColor Cyan

if (Test-Path "$SourcePath\scripts") {
    robocopy "$SourcePath\scripts" "$DeployPath\scripts" /E /NFL /NDL /NJH /NJS
    Write-Host "  ✅ Scripts da pasta /scripts movidos" -ForegroundColor Green
}

# Scripts da raiz
$rootScripts = Get-ChildItem "$SourcePath\*.ps1", "$SourcePath\*.bat", "$SourcePath\*.sh" -ErrorAction SilentlyContinue
foreach ($script in $rootScripts) {
    if ($script.Name -ne "reorganize.ps1") {
        Copy-Item $script.FullName "$DeployPath\scripts\" -Force
        Write-Host "  ✅ $($script.Name) movido" -ForegroundColor Green
    }
}

# Documentação de deploy
$deployDocs = @("DEPLOY_LINUX_GUIDE.md", "QUICK_DEPLOY.md", "TIMELINE.md", "SERVER-SETUP-GUIDE.md", "PIPELINE-GUIDE.md")
foreach ($doc in $deployDocs) {
    if (Test-Path "$SourcePath\docs\$doc") {
        Copy-Item "$SourcePath\docs\$doc" "$DeployPath\docs\" -Force
        Write-Host "  ✅ $doc movido" -ForegroundColor Green
    } elseif (Test-Path "$SourcePath\$doc") {
        Copy-Item "$SourcePath\$doc" "$DeployPath\docs\" -Force
        Write-Host "  ✅ $doc movido" -ForegroundColor Green
    }
}

# Arquivos de configuração
if (Test-Path "$SourcePath\teamfees.service") {
    Copy-Item "$SourcePath\teamfees.service" "$DeployPath\config\" -Force
    Write-Host "  ✅ teamfees.service movido" -ForegroundColor Green
}

Write-Host "`n📊 Reorganização concluída!" -ForegroundColor Green
Write-Host "📦 Código limpo: $CleanPath" -ForegroundColor Yellow
Write-Host "🛠️ Scripts deploy: $DeployPath" -ForegroundColor Yellow