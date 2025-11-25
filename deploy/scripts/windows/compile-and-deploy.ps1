# ========================================
# Script de Compilação e Deploy Automático
# ========================================

param(
    [string]$Environment = "production",
    [switch]$SkipBuild = $false,
    [switch]$SkipDeploy = $false
)

Write-Host "🚀 TeamFees - Compile and Deploy" -ForegroundColor Green
Write-Host "Environment: $Environment" -ForegroundColor Yellow

# Configurações
$ProjectPath = "TeamFees.dproj"
$OutputPath = "Linux64\Release"
$BinaryName = "TeamFees"

# ========================================
# 1. COMPILAÇÃO
# ========================================
if (-not $SkipBuild) {
    Write-Host "`n📦 Compilando projeto para Linux64..." -ForegroundColor Cyan
    
    # Verificar se projeto existe
    if (-not (Test-Path $ProjectPath)) {
        Write-Host "❌ Arquivo $ProjectPath não encontrado!" -ForegroundColor Red
        exit 1
    }
    
    # Compilar usando MSBuild
    $msbuildPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe"
    if (-not (Test-Path $msbuildPath)) {
        $msbuildPath = "${env:ProgramFiles}\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe"
    }
    if (-not (Test-Path $msbuildPath)) {
        # Tentar Delphi MSBuild
        $msbuildPath = "${env:ProgramFiles(x86)}\Embarcadero\Studio\22.0\bin\msbuild.exe"
    }
    
    if (-not (Test-Path $msbuildPath)) {
        Write-Host "❌ MSBuild não encontrado! Compile manualmente no Delphi." -ForegroundColor Red
        Write-Host "💡 Abra o Delphi → TeamFees.dproj → Build → Linux64 Release" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "🔨 Usando MSBuild: $msbuildPath" -ForegroundColor Gray
    
    & "$msbuildPath" $ProjectPath /t:Build /p:Config=Release /p:Platform=Linux64 /verbosity:minimal
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erro na compilação!" -ForegroundColor Red
        exit 1
    }
    
    # Verificar se binário foi gerado
    if (-not (Test-Path "$OutputPath\$BinaryName")) {
        Write-Host "❌ Binário não foi gerado em $OutputPath\$BinaryName" -ForegroundColor Red
        exit 1
    }
    
    $binarySize = (Get-Item "$OutputPath\$BinaryName").Length
    Write-Host "✅ Compilação concluída! Binário: $([math]::Round($binarySize/1MB, 2)) MB" -ForegroundColor Green
} else {
    Write-Host "⏭️ Pulando compilação (SkipBuild)" -ForegroundColor Yellow
}

# ========================================
# 2. COMMIT E PUSH (se binário foi alterado)
# ========================================
Write-Host "`n📝 Verificando mudanças no Git..." -ForegroundColor Cyan

# Verificar se há mudanças no binário
$gitStatus = git status --porcelain "$OutputPath\$BinaryName" 2>$null
if ($gitStatus) {
    Write-Host "📤 Binário foi alterado, fazendo commit..." -ForegroundColor Yellow
    
    git add "$OutputPath\$BinaryName"
    git add "$OutputPath\*.so" 2>$null  # Adicionar .so se existirem
    
    $commitMessage = "Build: Update Linux64 binary for $Environment deployment"
    git commit -m "$commitMessage"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Commit realizado" -ForegroundColor Green
        
        # Push
        Write-Host "📤 Fazendo push..." -ForegroundColor Cyan
        git push
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Push realizado com sucesso!" -ForegroundColor Green
        } else {
            Write-Host "❌ Erro no push!" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "❌ Erro no commit!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "ℹ️ Nenhuma mudança no binário detectada" -ForegroundColor Gray
}

# ========================================
# 3. TRIGGER DEPLOY VIA GITHUB ACTIONS
# ========================================
if (-not $SkipDeploy) {
    Write-Host "`n🚀 Disparando deploy via GitHub Actions..." -ForegroundColor Cyan
    
    # Verificar se gh CLI está instalado
    $ghInstalled = Get-Command gh -ErrorAction SilentlyContinue
    if ($ghInstalled) {
        Write-Host "🔄 Disparando workflow de deploy..." -ForegroundColor Yellow
        
        gh workflow run "deploy-real.yml" --field deploy_environment=$Environment
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Deploy disparado com sucesso!" -ForegroundColor Green
            Write-Host "🌐 Acompanhe em: https://github.com/Eduardovll/TeamFees/actions" -ForegroundColor Cyan
        } else {
            Write-Host "❌ Erro ao disparar deploy!" -ForegroundColor Red
        }
    } else {
        Write-Host "⚠️ GitHub CLI não instalado. Deploy manual necessário." -ForegroundColor Yellow
        Write-Host "💡 Instale: winget install GitHub.cli" -ForegroundColor Gray
        Write-Host "🌐 Ou acesse: https://github.com/Eduardovll/TeamFees/actions" -ForegroundColor Cyan
        Write-Host "   → Run workflow → TeamFees Real Deploy" -ForegroundColor Gray
    }
} else {
    Write-Host "⏭️ Pulando deploy (SkipDeploy)" -ForegroundColor Yellow
}

# ========================================
# 4. RESUMO
# ========================================
Write-Host "`n🎉 Processo concluído!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

if (-not $SkipBuild) {
    Write-Host "✅ Compilação: Concluída" -ForegroundColor Green
} else {
    Write-Host "⏭️ Compilação: Pulada" -ForegroundColor Yellow
}

Write-Host "✅ Git: Commit e push realizados" -ForegroundColor Green

if (-not $SkipDeploy) {
    Write-Host "✅ Deploy: Disparado via GitHub Actions" -ForegroundColor Green
} else {
    Write-Host "⏭️ Deploy: Pulado" -ForegroundColor Yellow
}

Write-Host "`n🌐 Links úteis:" -ForegroundColor Cyan
Write-Host "   Actions: https://github.com/Eduardovll/TeamFees/actions" -ForegroundColor White
Write-Host "   API: http://204.12.218.78:9000" -ForegroundColor White

Write-Host "`n💡 Próxima vez, use apenas:" -ForegroundColor Yellow
Write-Host "   .\deploy\scripts\windows\compile-and-deploy.ps1" -ForegroundColor White