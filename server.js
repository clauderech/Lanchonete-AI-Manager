/**
 * ESTE É UM EXEMPLO DE BACKEND (SERVER-SIDE)
 * Para usar:
 * 1. Crie uma pasta 'backend' no seu computador.
 * 2. Crie um arquivo package.json e instale: npm install express mysql2 cors body-parser
 * 3. Salve este arquivo como server.js
 * 4. Rode: node server.js
 */

const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
const bodyParser = require('body-parser');

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Configuração do Banco de Dados
const db = mysql.createConnection({
  host: 'localhost',
  user: 'root',      // Seu usuário do MySQL
  password: 'password', // Sua senha do MySQL
  database: 'lanchonete_db'
});

db.connect(err => {
  if (err) {
    console.error('Erro ao conectar no MySQL:', err);
    return;
  }
  console.log('Conectado ao MySQL');
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

app.listen(3001, () => {
  console.log('Servidor rodando na porta 3001');
});
