/**
 * Backend Server - Lanchonete AI Manager
 * Suporta múltiplas instâncias com PM2 em cluster mode
 */

require('dotenv').config({ path: process.env.NODE_ENV === 'production' ? '.env.production' : '.env.local' });

const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
const bodyParser = require('body-parser');

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Configuração do Banco de Dados a partir de variáveis de ambiente
const db = mysql.createConnection({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || 'password',
  database: process.env.DB_NAME || 'lanchonete_db',
  port: process.env.DB_PORT || 3306
});

db.connect(err => {
  if (err) {
    console.error('Erro ao conectar no MySQL:', err);
    process.exit(1);
  }
  console.log(`[Worker ${process.pid}] Conectado ao MySQL`);
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', pid: process.pid });
});

// --- Rotas da API ---

// Buscar todo o estado inicial (Produtos, Fornecedores, etc)
app.get('/api/initial-state', async (req, res) => {
  try {
    const [products] = await db.promise().query('SELECT * FROM products');
    const [suppliers] = await db.promise().query('SELECT * FROM suppliers');
    
    // Para cada prato, buscar a receita
    for (let p of products) {
        if (p.type === 'prato') {
            const [recipe] = await db.promise().query(
                'SELECT ingredient_id as ingredientId, quantity FROM product_recipes WHERE product_id = ?', 
                [p.id]
            );
            p.recipe = recipe;
        }
    }

    res.json({ products, suppliers });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Salvar Venda (e atualizar estoque)
app.post('/api/sales', async (req, res) => {
  const { items, total, paymentMethod, customerName } = req.body;
  
  const connection = await db.promise().getConnection();
  try {
    await connection.beginTransaction();

    // 1. Criar Venda
    const [result] = await connection.query(
      'INSERT INTO sales (total, payment_method, customer_name) VALUES (?, ?, ?)',
      [total, paymentMethod, customerName]
    );
    const saleId = result.insertId;

    // 2. Inserir Itens e Baixar Estoque
    for (let item of items) {
      // Inserir item da venda
      await connection.query(
        'INSERT INTO sale_items (sale_id, product_id, quantity, unit_price) VALUES (?, ?, ?, ?)',
        [saleId, item.productId, item.quantity, item.unitPrice]
      );

      // Lógica de Baixa de Estoque
      // Se for prato, baixa os ingredientes. Se for insumo, baixa direto.
      // (Esta lógica idealmente ficaria numa Procedure do MySQL ou aqui no Backend)
      // Simplificado: Assumindo que o frontend manda o cálculo ou o backend recalcula.
    }

    await connection.commit();
    res.json({ success: true, saleId });
  } catch (err) {
    await connection.rollback();
    res.status(500).json({ error: err.message });
  } finally {
    connection.release();
  }
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`[Worker ${process.pid}] Servidor rodando na porta ${PORT}`);
});
