# 🚀 TeamFees Deploy

Scripts e documentação para deploy do sistema TeamFees em ambiente Linux.

## 📁 Estrutura

```
TeamFees-Deploy/
├── scripts/             # 🛠️ Scripts de automação
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
   ./scripts/setup_server.sh
   ```

2. **No Windows (Delphi)**:
   ```powershell
   .\scripts\copy_sdk_libs.ps1
   .\scripts\create_lib_links.bat
   ```

### Deploy Regular

```powershell
.\scripts\deploy.ps1
```

## 🔗 Repositório Principal

[TeamFees - Código Fonte](https://github.com/seu-usuario/TeamFees)

---

**Versão**: 1.0.0