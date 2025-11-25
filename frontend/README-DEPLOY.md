# 🚀 Guia de Deploy - Frontend + Backend

## 📋 Cenários de Desenvolvimento

### **Cenário 1: Desenvolvimento Local (Atual)**
```
Frontend: http://localhost:3000
Backend:  http://localhost:9000
```

**Como usar:**
1. Inicie o backend Delphi (porta 9000)
2. Inicie o frontend: `npm run dev`
3. Acesse: http://localhost:3000

---

### **Cenário 2: Frontend Local + Backend em Produção**
```
Frontend: http://localhost:3000
Backend:  https://seu-backend-producao.com
```

**Como configurar:**

1. **Edite `.env.local`:**
```env
VITE_API_URL=https://seu-backend-producao.com
```

2. **Reinicie o frontend:**
```bash
npm run dev
```

3. **Pronto!** Seu frontend local agora aponta para o backend em produção.

---

### **Cenário 3: Ambos em Produção**
```
Frontend: https://seu-frontend.vercel.app
Backend:  https://seu-backend-producao.com
```

**Deploy Frontend (Vercel):**

1. **Configure variável de ambiente no Vercel:**
   - Dashboard → Settings → Environment Variables
   - `VITE_API_URL` = `https://seu-backend-producao.com`

2. **Deploy:**
```bash
npm run build
vercel --prod
```

---

## 🔧 Configuração do Backend (CORS)

O backend já está configurado para aceitar requisições de qualquer origem:

```pascal
THorse.Use(CORS);  // Permite qualquer origem
```

**Para produção, restrinja as origens permitidas:**
```pascal
THorse.Use(CORS('https://seu-frontend.vercel.app'));
```

---

## 🌐 URLs de Exemplo

### **Desenvolvimento:**
- Frontend: `http://localhost:3000`
- Backend: `http://localhost:9000`

### **Produção:**
- Frontend: `https://teamfees.vercel.app`
- Backend: `https://api.teamfees.com` (ou IP do VPS)

---

## ✅ Checklist de Deploy

### **Backend (VPS Linux):**
- [ ] Compilar para Linux64
- [ ] Upload executável + .so files
- [ ] Configurar .env no servidor
- [ ] Configurar PostgreSQL
- [ ] Criar systemd service
- [ ] Configurar Nginx (reverse proxy)
- [ ] Obter certificado SSL (Let's Encrypt)

### **Frontend (Vercel):**
- [ ] Configurar `VITE_API_URL` no Vercel
- [ ] Deploy: `vercel --prod`
- [ ] Configurar domínio customizado (opcional)

---

## 🔐 Segurança

### **CORS em Produção:**
Edite `ServerHorse.pas`:
```pascal
THorse.Use(CORS('https://seu-frontend.vercel.app'));
```

### **HTTPS Obrigatório:**
- Backend: Use Nginx + Let's Encrypt
- Frontend: Vercel já fornece HTTPS

---

## 📝 Notas

- **Desenvolvimento:** Use `.env.local` (não commitar)
- **Produção:** Configure variáveis no Vercel Dashboard
- **CORS:** Backend já aceita qualquer origem (ajustar em produção)
- **Custo:** Frontend grátis (Vercel) + Backend R$0-27/mês (VPS)
