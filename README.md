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