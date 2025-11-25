# ========================================
# Deploy Migrations - TeamFees
# ========================================

param(
    [string]$ServerIP = "SEU_IP_ORACLE_CLOUD",
    [string]$SSHKey = "$env:USERPROFILE\.ssh\oracle_key.pem"
)

Write-Host "📊 Fazendo deploy das migrations..." -ForegroundColor Cyan

# Upload arquivos SQL
Write-Host "`n📤 Enviando arquivos SQL..." -ForegroundColor Yellow

scp -i $SSHKey db/*.sql ubuntu@${ServerIP}:/opt/teamfees/

# Executar migrations em ordem
Write-Host "`n⚙️  Executando migrations..." -ForegroundColor Yellow

ssh -i $SSHKey ubuntu@${ServerIP} @"
    cd /opt/teamfees
    
    # Executar cada migration em ordem
    for file in \$(ls *.sql | sort); do
        echo "Executando: \$file"
        PGPASSWORD='sua_senha_segura_aqui' psql -U teamfees -d teamfees_db -f \$file
    done
    
    echo ""
    echo "✅ Migrations executadas!"
    
    # Verificar tabelas criadas
    echo ""
    echo "📋 Tabelas no banco:"
    PGPASSWORD='sua_senha_segura_aqui' psql -U teamfees -d teamfees_db -c "\dt"
"@

Write-Host "`n✅ Deploy de migrations concluído!" -ForegroundColor Green
