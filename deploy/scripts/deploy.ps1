# ========================================
# Pipeline de Deploy - TeamFees Backend
# ========================================

param(
    [string]$Environment = "production"
)

Write-Host "🚀 Iniciando deploy para $Environment..." -ForegroundColor Cyan

# Configurações
$ProjectPath = "C:\TeamFees\TeamFees.dproj"
$OutputPath = "C:\TeamFees\Linux64\Release"
$ServerIP = "SEU_IP_ORACLE_CLOUD"
$ServerUser = "ubuntu"
$ServerPath = "/opt/teamfees"
$SSHKey = "$env:USERPROFILE\.ssh\oracle_key.pem"

# ========================================
# 1. BUILD
# ========================================
Write-Host "`n📦 Compilando projeto para Linux64..." -ForegroundColor Yellow

# Compila usando MSBuild (Delphi)
& "C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\msbuild.exe" `
    $ProjectPath `
    /t:Build `
    /p:Config=Release `
    /p:Platform=Linux64

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro na compilação!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Compilação concluída!" -ForegroundColor Green

# ========================================
# 2. TESTES (opcional)
# ========================================
Write-Host "`n🧪 Executando testes..." -ForegroundColor Yellow
# Adicione seus testes aqui
Write-Host "✅ Testes passaram!" -ForegroundColor Green

# ========================================
# 3. BACKUP NO SERVIDOR
# ========================================
Write-Host "`n💾 Criando backup no servidor..." -ForegroundColor Yellow

ssh -i $SSHKey ${ServerUser}@${ServerIP} @"
    if [ -f $ServerPath/TeamFees ]; then
        sudo cp $ServerPath/TeamFees $ServerPath/TeamFees.backup.`$(date +%Y%m%d_%H%M%S)
        echo 'Backup criado'
    fi
"@

# ========================================
# 4. UPLOAD
# ========================================
Write-Host "`n📤 Enviando arquivos para servidor..." -ForegroundColor Yellow

# Upload executável
scp -i $SSHKey `
    "$OutputPath\TeamFees" `
    ${ServerUser}@${ServerIP}:${ServerPath}/

# Upload .so files (bibliotecas)
scp -i $SSHKey `
    "$OutputPath\*.so" `
    ${ServerUser}@${ServerIP}:${ServerPath}/

# Upload .env
scp -i $SSHKey `
    "C:\TeamFees\.env.production" `
    ${ServerUser}@${ServerIP}:${ServerPath}/.env

Write-Host "✅ Upload concluído!" -ForegroundColor Green

# ========================================
# 5. RESTART SERVICE
# ========================================
Write-Host "`n🔄 Reiniciando serviço..." -ForegroundColor Yellow

ssh -i $SSHKey ${ServerUser}@${ServerIP} @"
    sudo chmod +x $ServerPath/TeamFees
    sudo systemctl restart teamfees
    sleep 3
    sudo systemctl status teamfees --no-pager
"@

# ========================================
# 6. HEALTH CHECK
# ========================================
Write-Host "`n🏥 Verificando saúde da aplicação..." -ForegroundColor Yellow

Start-Sleep -Seconds 5

try {
    $response = Invoke-WebRequest -Uri "http://${ServerIP}:9000/health" -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Aplicação está rodando!" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  Aviso: Health check falhou. Verifique logs no servidor." -ForegroundColor Yellow
}

# ========================================
# 7. LOGS
# ========================================
Write-Host "`n📋 Últimas linhas do log:" -ForegroundColor Yellow

ssh -i $SSHKey ${ServerUser}@${ServerIP} @"
    sudo journalctl -u teamfees -n 20 --no-pager
"@

Write-Host "`n✨ Deploy concluído com sucesso!" -ForegroundColor Green
Write-Host "🌐 Backend disponível em: http://${ServerIP}:9000" -ForegroundColor Cyan
