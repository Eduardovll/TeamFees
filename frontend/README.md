# TeamFees Frontend

Frontend moderno para o sistema de gestão de mensalidades TeamFees.

## 🚀 Tecnologias

- React 18
- TypeScript
- Vite
- Tailwind CSS
- React Router
- Axios
- Lucide Icons

## 📦 Instalação

```bash
npm install
```

## 🏃 Executar

```bash
npm run dev
```

O frontend estará disponível em `http://localhost:3000`

## 🔧 Configuração

O frontend está configurado para fazer proxy das requisições `/api` para `http://localhost:9000` (backend).

## 📱 Funcionalidades Implementadas

### ✅ Autenticação
- Login com email ou telefone
- Logout
- Proteção de rotas
- Armazenamento de token

### ✅ Dashboard
- Visualização do perfil do usuário
- Menu lateral com navegação baseada em roles

### 🚧 Próximas Páginas (a implementar)
- Listagem de mensalidades (TREASURER/ADMIN)
- Listagem de pagamentos (TREASURER/ADMIN)
- Listagem de membros (ADMIN)
- Geração de ciclos (ADMIN)

## 🎨 Design

- Interface moderna e responsiva
- Gradientes e sombras suaves
- Ícones do Lucide React
- Paleta de cores azul/roxo

## 🔐 Controle de Acesso

- **PLAYER**: Apenas visualiza seu perfil
- **TREASURER**: Acesso a mensalidades e pagamentos
- **ADMIN**: Acesso total incluindo gestão de membros
