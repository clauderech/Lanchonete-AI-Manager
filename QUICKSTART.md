# 🚀 Guia Rápido de Início

## ⚡ Start em 3 Passos

### 1️⃣ Configurar Ambiente

```bash
# Clonar repositório
git clone https://github.com/clauderech/Lanchonete-AI-Manager.git
cd Lanchonete-AI-Manager

# Instalar dependências
npm install

# Copiar arquivo de ambiente
cp .env.local.example .env.local
```

Edite `.env.local` e adicione sua chave do Gemini:
```env
API_KEY=sua-chave-gemini-aqui
```

> 💡 Obtenha gratuitamente em: https://ai.google.dev/

---

### 2️⃣ Iniciar Aplicação

**Modo Desenvolvimento (sem backend):**
```bash
npm run dev
```

Acesse: `http://localhost:5173`

**Com Backend (produção completa):**

Terminal 1 - Backend:
```bash
npm run start
```

Terminal 2 - Frontend:
```bash
npm run dev
```

---

### 3️⃣ Fazer Login

**Usuários de Demonstração:**

| Usuário | Senha | Perfil |
|---------|-------|--------|
| admin | admin123 | Administrador |
| operador | op123 | Operador |
| caixa | caixa123 | Caixa |

---

## 📊 Principais Funcionalidades

### 🏪 PDV (Ponto de Venda)
- Venda rápida ou por comandas
- Controle de estoque automático
- Cálculo de disponibilidade por receita

### 📦 Gestão de Estoque
- Cadastro de insumos e pratos
- Fichas técnicas (receitas)
- Alertas de estoque baixo

### 💰 Controle Financeiro
- Dashboard com gráficos
- Despesas operacionais
- Abertura/fechamento de caixa
- Relatórios gerenciais

### 🤖 Inteligência Artificial
- Insights de negócio
- Sugestões de compra
- Análise de tendências

---

## 🔐 Permissões por Perfil

### 👑 Admin (Completo)
- ✅ Todas as funcionalidades
- ✅ Relatórios financeiros
- ✅ Gestão de produtos
- ✅ Controle de usuários

### 👨‍💼 Operador (Operacional)
- ✅ PDV
- ✅ Estoque e receitas
- ✅ Compras
- ✅ Lista de compras
- ❌ Financeiro
- ❌ Despesas

### 💵 Caixa (Vendas)
- ✅ PDV
- ✅ Controle de caixa
- ✅ Dashboard básico
- ❌ Estoque
- ❌ Compras
- ❌ Relatórios

---

## 🎯 Workflow Recomendado

### Configuração Inicial (Admin)

1. **Cadastrar Fornecedores**
   - Menu: `Entrada de Notas` → Criar fornecedor

2. **Cadastrar Insumos**
   - Menu: `Estoque / Receitas`
   - Tipo: Insumo (ingredientes)
   - Informar: custo, estoque, fornecedor

3. **Cadastrar Pratos**
   - Menu: `Estoque / Receitas`
   - Tipo: Prato (produtos finais)
   - Criar ficha técnica (receita)

4. **Abrir Caixa**
   - Menu: `Caixa`
   - Informar valor inicial

### Operação Diária

#### Vendas (Caixa/Operador)
1. Menu: `PDV (Vendas)`
2. Escolher: Venda Rápida ou Comanda
3. Adicionar produtos
4. Finalizar venda

#### Reposição (Operador)
1. Menu: `Lista de Compras`
2. Auto-preencher (estoque baixo)
3. Selecionar fornecedor
4. Confirmar entrada

#### Fechamento (Admin/Caixa)
1. Menu: `Caixa`
2. Informar valor contado
3. Verificar diferença
4. Confirmar fechamento

---

## 📱 Atalhos de Teclado

| Tecla | Ação |
|-------|------|
| `Ctrl + D` | Dashboard |
| `Ctrl + P` | PDV |
| `Ctrl + E` | Estoque |
| `Ctrl + L` | Logout |

*(Implementação futura)*

---

## 🐛 Solução de Problemas

### Erro: "API_KEY not found"
**Solução:** Configure `.env.local` com sua chave do Gemini

### Erro: "Não foi possível conectar ao banco"
**Solução:** 
1. Verifique se o MySQL está rodando
2. Importe `database_unified.sql`
3. Configure credenciais em `.env.local`

### Tela de login não aparece
**Solução:** Limpe o localStorage:
```javascript
// No console do navegador
localStorage.clear()
location.reload()
```

### Produtos não aparecem no PDV
**Verifique:**
- ✅ Produtos estão cadastrados como "prato"
- ✅ Possui receita configurada
- ✅ Ingredientes têm estoque disponível

---

## 🎨 Personalização

### Alterar cores do tema
Edite `App.tsx`:
```typescript
// Cards do dashboard
className="bg-gradient-to-br from-blue-500 to-blue-600"
// Altere: blue → purple, green, red, etc.
```

### Adicionar novo usuário demo
Edite `components/Login.tsx`:
```typescript
const demoUsers = [
  { username: 'novo', password: '123', name: 'Novo', role: 'operador' }
];
```

### Mudar logo
Substitua no sidebar:
```tsx
<div className="w-8 h-8 bg-blue-600">
  <img src="/logo.png" alt="Logo" />
</div>
```

---

## 📚 Documentação Completa

- 📖 [README.md](./README.md) - Visão geral
- 🔧 [COMPONENTS_README.md](./COMPONENTS_README.md) - Componentes
- 🚀 [DEPLOY.md](./DEPLOY.md) - Deploy em produção
- 📝 [CHANGELOG.md](./CHANGELOG.md) - Novas funcionalidades

---

## 🤝 Contribuir

```bash
# Fork o projeto
git clone https://github.com/seu-usuario/Lanchonete-AI-Manager.git

# Criar branch
git checkout -b feature/nova-funcionalidade

# Commit
git commit -m "feat: adiciona nova funcionalidade"

# Push
git push origin feature/nova-funcionalidade

# Criar Pull Request
```

---

## 📞 Suporte

- 🐛 **Bugs:** Abra uma issue no GitHub
- 💡 **Sugestões:** Discussions no GitHub
- 📧 **Email:** suporte@lanchonete.ai

---

**Pronto para usar! 🎉**

Desenvolvido com ❤️ por Claude + GitHub Copilot
