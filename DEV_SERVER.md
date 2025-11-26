# 🛠️ Gerenciamento do Servidor de Desenvolvimento

## Scripts Disponíveis

### **Iniciar Servidor**
```bash
./start-dev.sh
# OU
npm run dev:start
```
- ✅ Garante que apenas UMA instância rode
- ✅ Mata processos órfãos automaticamente
- ✅ Cria lock file para prevenir múltiplas instâncias
- ✅ Exibe PID e informações úteis

### **Parar Servidor**
```bash
./stop-dev.sh
# OU
npm run dev:stop
```
- ✅ Para o servidor graciosamente
- ✅ Limpa lock files
- ✅ Remove processos órfãos

### **Ver Status**
```bash
./status-dev.sh
# OU
npm run dev:status
```
- ✅ Mostra se está rodando ou parado
- ✅ Exibe PID do processo
- ✅ Mostra URL de acesso
- ✅ Lista processos Vite ativos

## Uso no Servidor Remoto (SSH)

### **Passo 1: Conectar**
```bash
ssh -p2380 claus@192.168.15.3
```

### **Passo 2: Ir para o diretório**
```bash
cd Lanchonete-AI-Manager
```

### **Passo 3: Parar tudo primeiro**
```bash
./stop-dev.sh
```

### **Passo 4: Iniciar**
```bash
./start-dev.sh
```

### **Passo 5: Acessar**
Abra o navegador em:
```
http://192.168.15.3:5173/
```

## Solução de Problemas

### **Erro: "Porta 5173 em uso"**
```bash
./stop-dev.sh
./start-dev.sh
```

### **Nota sobre Porta 3000**
A porta 3000 é usada pela API Node existente e **não deve ser alterada**.  
O Vite roda na porta **5173**.

### **Erro: "Servidor já está rodando"**
Isso é NORMAL! Significa que o sistema está funcionando corretamente.
Se quiser reiniciar:
```bash
./stop-dev.sh
./start-dev.sh
```

### **Ver processos manualmente**
```bash
ps aux | grep vite
```

### **Matar tudo manualmente (emergência)**
```bash
pkill -9 -f 'node.*vite'
rm -f /tmp/lanchonete-dev.*
```

## Configurações

O arquivo `vite.config.ts` foi configurado com:
- **strictPort: true** - Falha se a porta 5173 estiver ocupada (previne múltiplas instâncias)
- **port: 5173** - Porta padrão do Vite (não conflita com API Node na porta 3000)
- **host: 0.0.0.0** - Aceita conexões de qualquer IP

## Lock Files

- `/tmp/lanchonete-dev.lock` - Indica que há uma instância rodando
- `/tmp/lanchonete-dev.pid` - Armazena o PID do processo

Esses arquivos são automaticamente criados/removidos pelos scripts.
