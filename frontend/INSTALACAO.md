# 📦 Guia de Instalação do Frontend

## ⚠️ Pré-requisitos

Você precisa instalar o **Node.js** antes de rodar o frontend.

### 1️⃣ Instalar Node.js

1. Acesse: https://nodejs.org/
2. Baixe a versão **LTS** (recomendada)
3. Execute o instalador
4. Siga as instruções (deixe todas as opções padrão marcadas)
5. Reinicie o CMD após a instalação

### 2️⃣ Verificar Instalação

Abra um novo CMD e digite:

```bash
node --version
npm --version
```

Deve aparecer algo como:
```
v20.x.x
10.x.x
```

### 3️⃣ Instalar Dependências do Frontend

```bash
cd C:\TeamFees\frontend
npm install
```

Aguarde alguns minutos enquanto baixa todas as dependências.

### 4️⃣ Rodar o Frontend

```bash
npm run dev
```

O frontend estará disponível em: **http://localhost:3000**

---

## 🚀 Comandos Úteis

- `npm run dev` - Inicia o servidor de desenvolvimento
- `npm run build` - Gera build de produção
- `npm run preview` - Visualiza o build de produção

---

## 🔧 Troubleshooting

### Erro: 'npm' não é reconhecido
- Você precisa instalar o Node.js (passo 1)
- Após instalar, **reinicie o CMD**

### Erro: EACCES ou permissão negada
- Execute o CMD como Administrador

### Porta 3000 já está em uso
- Mude a porta no arquivo `vite.config.ts`:
  ```ts
  server: {
    port: 3001, // ou outra porta
  }
  ```

---

## 📱 Testando o Sistema

1. Certifique-se que o **backend** está rodando na porta 9000
2. Acesse http://localhost:3000
3. Faça login com:
   - **Identifier**: admin@teamfees.com
   - **Password**: (sua senha do banco)

---

## 🎯 Próximos Passos

Após rodar o frontend, você verá:
- ✅ Tela de login moderna
- ✅ Dashboard com perfil do usuário
- ✅ Menu lateral baseado no seu role

As páginas de Mensalidades, Pagamentos e Membros serão implementadas em seguida.
