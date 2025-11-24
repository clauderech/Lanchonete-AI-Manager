# 🚀 Deploy no Digital Ocean - Lanchonete AI Manager

Este guia irá ajudá-lo a fazer o deploy da aplicação **Lanchonete AI Manager** no Digital Ocean usando Droplets ou App Platform.

## 📋 Pré-requisitos

- Conta no [Digital Ocean](https://www.digitalocean.com/)
- Conta no [Google AI Studio](https://ai.google.dev/) para obter a API Key do Gemini
- (Opcional) Domínio próprio

---

## 🎯 Opção 1: Deploy com Digital Ocean App Platform (Recomendado - Mais Fácil)

### Vantagens
- ✅ Configuração automática
- ✅ Auto-scaling
- ✅ SSL/HTTPS automático
- ✅ Integração com GitHub
- ✅ Deploy automático a cada commit

### Passos

1. **No Digital Ocean Dashboard:**
   - Acesse "Apps" → "Create App"
   - Conecte seu repositório GitHub
   - Selecione o repositório `Lanchonete-AI-Manager`

2. **Configurar Build:**
   ```
   Build Command: npm install && npm run build
   Run Command: npm run start:prod
   ```

3. **Configurar Variáveis de Ambiente:**
   - Vá em "Environment Variables"
   - Adicione as seguintes variáveis:
   ```
   GEMINI_API_KEY=sua-chave-api-gemini
   DB_HOST=seu-db-host.db.ondigitalocean.com
   DB_USER=doadmin
   DB_PASSWORD=sua-senha-db
   DB_NAME=lanchonete_db
   DB_PORT=25060
   NODE_ENV=production
   PORT=3001
   ```

4. **Adicionar Banco de Dados:**
   - No App Platform, adicione um "Managed Database"
   - Escolha MySQL 8.0
   - Selecione o plano (Basic é suficiente para começar)
   - A conexão será configurada automaticamente

5. **Deploy:**
   - Clique em "Create Resources"
   - Aguarde o build e deploy (5-10 minutos)
   - Sua aplicação estará disponível em `https://seu-app.ondigitalocean.app`

---

## 🔧 Opção 2: Deploy Manual com Droplet (Mais Controle)

### Vantagens
- ✅ Controle total do servidor
- ✅ Menor custo a longo prazo
- ✅ Suporta múltiplas instâncias
- ✅ Customização avançada

### Passo 1: Criar Droplet

1. **No Digital Ocean Dashboard:**
   - Crie um Droplet Ubuntu 22.04 LTS
   - Escolha o plano: **Basic - 2GB RAM / 1 vCPU** ($12/mês)
   - Região: Escolha a mais próxima dos seus usuários
   - Autenticação: SSH Key ou Password

2. **Conecte ao servidor:**
   ```bash
   ssh root@seu-ip-do-droplet
   ```

### Passo 2: Configurar Servidor

```bash
# Atualizar sistema
apt update && apt upgrade -y

# Instalar Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Instalar PM2 globalmente
npm install -g pm2

# Instalar MySQL
apt install -y mysql-server

# Configurar MySQL
mysql_secure_installation
```

### Passo 3: Configurar Banco de Dados

```bash
# Entrar no MySQL
mysql -u root -p

# Criar banco e usuário
CREATE DATABASE lanchonete_db;
CREATE USER 'lanchonete_user'@'localhost' IDENTIFIED BY 'senha-segura-aqui';
GRANT ALL PRIVILEGES ON lanchonete_db.* TO 'lanchonete_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;

# Importar estrutura do banco
mysql -u lanchonete_user -p lanchonete_db < database.sql
```

### Passo 4: Clonar e Configurar Aplicação

```bash
# Criar diretório para aplicação
mkdir -p /var/www/lanchonete
cd /var/www/lanchonete

# Clonar repositório
git clone https://github.com/clauderech/Lanchonete-AI-Manager.git .

# Instalar dependências
npm install

# Criar arquivo de ambiente
nano .env.production
```

Adicione no `.env.production`:
```env
GEMINI_API_KEY=sua-chave-api-gemini
DB_HOST=localhost
DB_USER=lanchonete_user
DB_PASSWORD=senha-segura-aqui
DB_NAME=lanchonete_db
DB_PORT=3306
NODE_ENV=production
PORT=3001
```

```bash
# Build da aplicação
npm run build

# Criar diretório de logs
mkdir -p logs
```

### Passo 5: Configurar PM2

```bash
# Iniciar aplicação com PM2
npm run start:prod

# Salvar configuração PM2
pm2 save

# Configurar PM2 para iniciar no boot
pm2 startup
# Execute o comando que aparecer na tela

# Verificar status
pm2 status
pm2 logs
```

### Passo 6: Instalar e Configurar NGINX

```bash
# Instalar NGINX
apt install -y nginx

# Criar configuração do site
nano /etc/nginx/sites-available/lanchonete
```

Cole o conteúdo do arquivo `nginx.conf` do projeto (ajuste o `server_name`):

```bash
# Criar link simbólico
ln -s /etc/nginx/sites-available/lanchonete /etc/nginx/sites-enabled/

# Remover configuração padrão
rm /etc/nginx/sites-enabled/default

# Testar configuração
nginx -t

# Reiniciar NGINX
systemctl restart nginx
systemctl enable nginx
```

### Passo 7: Configurar SSL com Let's Encrypt

```bash
# Instalar Certbot
apt install -y certbot python3-certbot-nginx

# Obter certificado SSL (substitua seu-dominio.com)
certbot --nginx -d seu-dominio.com -d www.seu-dominio.com

# Renovação automática já está configurada
certbot renew --dry-run
```

### Passo 8: Configurar Firewall

```bash
# Configurar UFW
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw enable
ufw status
```

---

## 📊 Gerenciando Múltiplas Instâncias

O projeto já está configurado para usar PM2 em **cluster mode**, criando automaticamente uma instância por núcleo de CPU.

### Verificar quantas instâncias estão rodando:
```bash
pm2 status
```

### Ajustar número de instâncias manualmente:
```bash
# Editar ecosystem.config.js
nano ecosystem.config.js

# Mudar de 'max' para número específico:
instances: 4  # Para 4 instâncias
```

### Comandos úteis:
```bash
# Ver logs em tempo real
pm2 logs lanchonete-backend

# Monitorar recursos
pm2 monit

# Reiniciar
pm2 restart ecosystem.config.js

# Parar
pm2 stop ecosystem.config.js

# Recarregar (sem downtime)
pm2 reload ecosystem.config.js
```

---

## 🐳 Opção 3: Deploy com Docker

### Construir imagem:
```bash
docker build -t lanchonete-ai-manager \
  --build-arg GEMINI_API_KEY=sua-chave-api \
  .
```

### Executar container:
```bash
docker run -d \
  --name lanchonete-app \
  -p 3000:3000 \
  -p 3001:3001 \
  -e DB_HOST=seu-db-host \
  -e DB_USER=usuario \
  -e DB_PASSWORD=senha \
  -e DB_NAME=lanchonete_db \
  lanchonete-ai-manager
```

---

## 🔍 Monitoramento e Manutenção

### Logs:
```bash
# Logs do PM2
pm2 logs

# Logs do NGINX
tail -f /var/log/nginx/lanchonete-access.log
tail -f /var/log/nginx/lanchonete-error.log
```

### Atualizar aplicação:
```bash
cd /var/www/lanchonete
git pull origin main
npm install
npm run build
pm2 reload ecosystem.config.js
```

### Backup do banco de dados:
```bash
# Criar backup
mysqldump -u lanchonete_user -p lanchonete_db > backup-$(date +%Y%m%d).sql

# Restaurar backup
mysql -u lanchonete_user -p lanchonete_db < backup-20250124.sql
```

---

## 💰 Custos Estimados (Digital Ocean)

### App Platform:
- **Basic Plan**: $5/mês (512MB RAM)
- **Professional Plan**: $12/mês (1GB RAM) - Recomendado
- **Managed Database**: $15/mês (MySQL 8.0)
- **Total**: ~$27/mês

### Droplet Manual:
- **Droplet**: $12/mês (2GB RAM)
- **Banco de dados no mesmo Droplet**: $0
- **Total**: $12/mês (mais econômico)

---

## 🆘 Troubleshooting

### Aplicação não inicia:
```bash
pm2 logs lanchonete-backend
# Verifique as variáveis de ambiente
cat .env.production
```

### Erro de conexão com banco:
```bash
# Testar conexão MySQL
mysql -u lanchonete_user -p -h localhost lanchonete_db
```

### NGINX mostrando erro 502:
```bash
# Verificar se aplicação está rodando
pm2 status
# Verificar logs do NGINX
tail -f /var/log/nginx/lanchonete-error.log
```

### SSL não funciona:
```bash
# Renovar certificado
certbot renew --force-renewal
systemctl restart nginx
```

---

## 📞 Suporte

- **Documentação Digital Ocean**: https://docs.digitalocean.com/
- **PM2 Docs**: https://pm2.keymetrics.io/
- **NGINX Docs**: https://nginx.org/en/docs/

---

## ✅ Checklist de Deploy

- [ ] Criar conta no Digital Ocean
- [ ] Obter API Key do Google Gemini
- [ ] Escolher método de deploy (App Platform ou Droplet)
- [ ] Configurar banco de dados
- [ ] Configurar variáveis de ambiente
- [ ] Fazer build da aplicação
- [ ] Configurar domínio (opcional)
- [ ] Configurar SSL/HTTPS
- [ ] Testar aplicação em produção
- [ ] Configurar backups automáticos
- [ ] Configurar monitoramento

---

**Pronto!** 🎉 Sua aplicação está agora rodando em produção no Digital Ocean com suporte para múltiplas instâncias!
