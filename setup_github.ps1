# Script para configurar GitHub automaticamente
param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubUsername,
    
    [Parameter(Mandatory=$false)]
    [string]$ServerIP = "",
    
    [Parameter(Mandatory=$false)]
    [string]$ServerUser = "administrator"
)

Write-Host "🚀 Configurando GitHub para TeamFees..." -ForegroundColor Green
Write-Host "👤 Usuario: $GitHubUsername" -ForegroundColor Yellow

# Verificar se estamos na pasta correta
if (!(Test-Path "TeamFees.dpr")) {
    Write-Host "❌ Execute este script na pasta C:\TeamFees-Clean" -ForegroundColor Red
    exit 1
}

# Configurar Git se necessário
Write-Host "📝 Configurando Git..." -ForegroundColor Cyan
$gitUser = git config --global user.name
if (!$gitUser) {
    $name = Read-Host "Digite seu nome para o Git"
    $email = Read-Host "Digite seu email para o Git"
    git config --global user.name "$name"
    git config --global user.email "$email"
    Write-Host "✅ Git configurado" -ForegroundColor Green
}

# Adicionar remote do repositório principal
Write-Host "🔗 Configurando remote do repositório principal..." -ForegroundColor Cyan
$remoteUrl = "https://github.com/$GitHubUsername/TeamFees.git"

try {
    git remote remove origin 2>$null
    git remote add origin $remoteUrl
    git branch -M main
    Write-Host "✅ Remote configurado: $remoteUrl" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Erro ao configurar remote. Configure manualmente:" -ForegroundColor Yellow
    Write-Host "   git remote add origin $remoteUrl" -ForegroundColor White
}

# Fazer push inicial
Write-Host "📤 Fazendo push inicial..." -ForegroundColor Cyan
try {
    git push -u origin main
    Write-Host "✅ Push realizado com sucesso!" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Erro no push. Verifique se o repositório foi criado no GitHub:" -ForegroundColor Yellow
    Write-Host "   https://github.com/$GitHubUsername/TeamFees" -ForegroundColor White
}

# Configurar repositório de deploy
Write-Host "🛠️ Configurando repositório de deploy..." -ForegroundColor Cyan
$deployPath = "C:\TeamFees-Deploy"

if (Test-Path $deployPath) {
    Push-Location $deployPath
    
    try {
        git init
        git add .
        git commit -m "Initial commit - deploy scripts and documentation"
        git remote add origin "https://github.com/$GitHubUsername/TeamFees-Deploy.git"
        git branch -M main
        git push -u origin main
        Write-Host "✅ Repositório de deploy configurado!" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Erro no repositório de deploy. Configure manualmente." -ForegroundColor Yellow
    }
    
    Pop-Location
} else {
    Write-Host "⚠️ Pasta C:\TeamFees-Deploy não encontrada" -ForegroundColor Yellow
}

# Gerar informações para secrets
Write-Host "`n🔐 Configuração de Secrets no GitHub:" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

Write-Host "`n📋 Adicione estes secrets em:" -ForegroundColor Yellow
Write-Host "   https://github.com/$GitHubUsername/TeamFees/settings/secrets/actions" -ForegroundColor White

Write-Host "`n🔑 Secrets necessários:" -ForegroundColor Yellow

if ($ServerIP) {
    Write-Host "   SERVER_HOST = $ServerIP" -ForegroundColor Green
} else {
    Write-Host "   SERVER_HOST = SEU_IP_DO_SERVIDOR" -ForegroundColor White
}

Write-Host "   SERVER_USER = $ServerUser" -ForegroundColor Green
Write-Host "   SSH_PRIVATE_KEY = [Conteúdo da chave SSH privada]" -ForegroundColor White
Write-Host "   DEPLOY_TOKEN = [Token do GitHub - criar em https://github.com/settings/tokens]" -ForegroundColor White

# Verificar chave SSH
Write-Host "`n🔑 Verificando chave SSH..." -ForegroundColor Cyan
$sshKeyPath = "$env:USERPROFILE\.ssh\id_rsa"

if (Test-Path $sshKeyPath) {
    Write-Host "✅ Chave SSH encontrada em: $sshKeyPath" -ForegroundColor Green
    Write-Host "📋 Para copiar a chave privada:" -ForegroundColor Yellow
    Write-Host "   Get-Content $sshKeyPath | clip" -ForegroundColor White
} else {
    Write-Host "⚠️ Chave SSH não encontrada. Para gerar:" -ForegroundColor Yellow
    Write-Host "   ssh-keygen -t rsa -b 4096 -C `"seu-email@exemplo.com`"" -ForegroundColor White
}

# Próximos passos
Write-Host "`n🎯 Próximos passos:" -ForegroundColor Cyan
Write-Host "   1. Criar repositórios no GitHub (se ainda não criou)" -ForegroundColor White
Write-Host "   2. Configurar secrets listados acima" -ForegroundColor White
Write-Host "   3. Fazer um commit de teste para ativar CI/CD" -ForegroundColor White
Write-Host "   4. Verificar Actions em: https://github.com/$GitHubUsername/TeamFees/actions" -ForegroundColor White

Write-Host "`n✨ Configuração concluída!" -ForegroundColor Green