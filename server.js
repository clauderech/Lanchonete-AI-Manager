/**
 * Backend Server - Lanchonete AI Manager (Unified Database Version)
 * Suporta múltiplas instâncias com PM2 em cluster mode
 * Integrado com database_unified.sql
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

// =========================================
// ROTAS DA API
// =========================================

// --- ESTADO INICIAL ---
app.get('/api/initial-state', async (req, res) => {
  try {
    const [products] = await db.promise().query('SELECT * FROM products WHERE is_active = TRUE');
    const [suppliers] = await db.promise().query('SELECT * FROM suppliers');
    const [customers] = await db.promise().query('SELECT * FROM customers');
    const [sales] = await db.promise().query('SELECT * FROM sales ORDER BY date DESC LIMIT 100');
    const [purchases] = await db.promise().query('SELECT * FROM purchases ORDER BY date DESC LIMIT 100');
    const [shoppingList] = await db.promise().query('SELECT * FROM shopping_list WHERE is_purchased = FALSE');
    const [activeComandas] = await db.promise().query('SELECT * FROM comandas WHERE status = "open"');
    
    // Buscar receitas para cada prato
    for (let p of products) {
      if (p.type === 'prato') {
        const [recipe] = await db.promise().query(
          'SELECT ingredient_id as ingredientId, quantity, unit FROM product_recipes WHERE product_id = ?',
          [p.id]
        );
        p.recipe = recipe;
      }
    }

    // Buscar itens de cada venda
    for (let sale of sales) {
      const [items] = await db.promise().query(
        'SELECT product_id as productId, product_name as productName, quantity, unit_price as unitPrice FROM sale_items WHERE sale_id = ?',
        [sale.id]
      );
      sale.items = items;
    }

    // Buscar itens de cada comanda
    for (let comanda of activeComandas) {
      const [items] = await db.promise().query(
        'SELECT product_id as productId, product_name as productName, quantity, unit_price as unitPrice, status FROM comanda_items WHERE comanda_id = ?',
        [comanda.id]
      );
      comanda.items = items;
    }

    res.json({ products, suppliers, customers, sales, purchases, shoppingList, activeComandas });
  } catch (err) {
    console.error('Erro ao buscar estado inicial:', err);
    res.status(500).json({ error: err.message });
  }
});

// --- VENDAS ---
app.post('/api/sales', async (req, res) => {
  const { items, total, subtotal, discount = 0, paymentMethod, customerName, customerPhone, comandaId, notes } = req.body;
  
  const connection = await db.promise().getConnection();
  try {
    await connection.beginTransaction();

    const saleId = `sale_${Date.now()}`;
    
    // Criar venda
    await connection.query(
      `INSERT INTO sales (id, total, subtotal, discount, payment_method, customer_name, customer_phone, comanda_id, notes)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [saleId, total, subtotal || total, discount, paymentMethod, customerName, customerPhone, comandaId, notes]
    );

    // Inserir itens (triggers do banco vão baixar estoque automaticamente)
    for (let item of items) {
      await connection.query(
        `INSERT INTO sale_items (sale_id, product_id, product_name, quantity, unit_price)
         VALUES (?, ?, ?, ?, ?)`,
        [saleId, item.productId, item.productName, item.quantity, item.unitPrice]
      );
    }

    await connection.commit();
    res.json({ success: true, saleId });
  } catch (err) {
    await connection.rollback();
    console.error('Erro ao criar venda:', err);
    res.status(500).json({ error: err.message });
  } finally {
    connection.release();
  }
});

app.get('/api/sales', async (req, res) => {
  try {
    const { startDate, endDate, limit = 100 } = req.query;
    let query = 'SELECT * FROM sales';
    let params = [];
    
    if (startDate && endDate) {
      query += ' WHERE date BETWEEN ? AND ?';
      params = [startDate, endDate];
    }
    
    query += ' ORDER BY date DESC LIMIT ?';
    params.push(parseInt(limit));
    
    const [sales] = await db.promise().query(query, params);
    
    for (let sale of sales) {
      const [items] = await db.promise().query(
        'SELECT product_id as productId, product_name as productName, quantity, unit_price as unitPrice FROM sale_items WHERE sale_id = ?',
        [sale.id]
      );
      sale.items = items;
    }
    
    res.json(sales);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- COMANDAS ---
app.post('/api/comandas', async (req, res) => {
  const { customerName, tableNumber } = req.body;
  const comandaId = `comanda_${Date.now()}`;
  
  try {
    await db.promise().query(
      `INSERT INTO comandas (id, customer_name, table_number) VALUES (?, ?, ?)`,
      [comandaId, customerName, tableNumber]
    );
    res.json({ success: true, comandaId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/comandas/:id', async (req, res) => {
  const { id } = req.params;
  const { items } = req.body;
  
  const connection = await db.promise().getConnection();
  try {
    await connection.beginTransaction();
    
    // Deletar itens anteriores
    await connection.query('DELETE FROM comanda_items WHERE comanda_id = ?', [id]);
    
    // Inserir novos itens
    let total = 0;
    for (let item of items) {
      await connection.query(
        `INSERT INTO comanda_items (comanda_id, product_id, product_name, quantity, unit_price)
         VALUES (?, ?, ?, ?, ?)`,
        [id, item.productId, item.productName, item.quantity, item.unitPrice]
      );
      total += item.quantity * item.unitPrice;
    }
    
    // Atualizar total
    await connection.query('UPDATE comandas SET total = ? WHERE id = ?', [total, id]);
    
    await connection.commit();
    res.json({ success: true });
  } catch (err) {
    await connection.rollback();
    res.status(500).json({ error: err.message });
  } finally {
    connection.release();
  }
});

app.post('/api/comandas/:id/close', async (req, res) => {
  const { id } = req.params;
  const { paymentMethod } = req.body;
  
  try {
    // Buscar comanda
    const [comandas] = await db.promise().query('SELECT * FROM comandas WHERE id = ?', [id]);
    if (comandas.length === 0) {
      return res.status(404).json({ error: 'Comanda não encontrada' });
    }
    
    const comanda = comandas[0];
    
    // Buscar itens
    const [items] = await db.promise().query(
      'SELECT product_id as productId, product_name as productName, quantity, unit_price as unitPrice FROM comanda_items WHERE comanda_id = ?',
      [id]
    );
    
    // Criar venda a partir da comanda
    const saleData = {
      items,
      total: comanda.total,
      subtotal: comanda.total,
      paymentMethod,
      customerName: comanda.customer_name,
      comandaId: id
    };
    
    // Reutilizar a lógica de criação de venda
    const connection = await db.promise().getConnection();
    await connection.beginTransaction();
    
    const saleId = `sale_${Date.now()}`;
    
    await connection.query(
      `INSERT INTO sales (id, total, subtotal, payment_method, customer_name, comanda_id)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [saleId, saleData.total, saleData.subtotal, paymentMethod, saleData.customerName, id]
    );
    
    for (let item of items) {
      await connection.query(
        `INSERT INTO sale_items (sale_id, product_id, product_name, quantity, unit_price)
         VALUES (?, ?, ?, ?, ?)`,
        [saleId, item.productId, item.productName, item.quantity, item.unitPrice]
      );
    }
    
    // Fechar comanda
    await connection.query(
      'UPDATE comandas SET status = "closed", closed_at = NOW(), payment_method = ? WHERE id = ?',
      [paymentMethod, id]
    );
    
    await connection.commit();
    connection.release();
    
    res.json({ success: true, saleId });
  } catch (err) {
    console.error('Erro ao fechar comanda:', err);
    res.status(500).json({ error: err.message });
  }
});

// --- COMPRAS ---
app.post('/api/purchases', async (req, res) => {
  const { supplierId, items, total, invoiceNumber, paymentMethod, notes } = req.body;
  
  const connection = await db.promise().getConnection();
  try {
    await connection.beginTransaction();
    
    const purchaseId = `purchase_${Date.now()}`;
    
    await connection.query(
      `INSERT INTO purchases (id, supplier_id, total, invoice_number, payment_method, notes)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [purchaseId, supplierId, total, invoiceNumber, paymentMethod || 'cash', notes]
    );
    
    for (let item of items) {
      await connection.query(
        `INSERT INTO purchase_items (purchase_id, product_id, product_name, quantity, unit_price)
         VALUES (?, ?, ?, ?, ?)`,
        [purchaseId, item.productId, item.productName, item.quantity, item.unitPrice]
      );
    }
    
    await connection.commit();
    res.json({ success: true, purchaseId });
  } catch (err) {
    await connection.rollback();
    res.status(500).json({ error: err.message });
  } finally {
    connection.release();
  }
});

// --- PRODUTOS ---
app.post('/api/products', async (req, res) => {
  try {
    const product = req.body;
    const productId = `${product.type}_${Date.now()}`;
    
    await db.promise().query(
      `INSERT INTO products (id, name, type, price, cost, stock, min_stock, max_stock, unit, supplier_id, category, description, barcode)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [productId, product.name, product.type, product.price || 0, product.cost || 0, product.stock || 0,
       product.minStock || 10, product.maxStock, product.unit || 'un', product.supplierId, product.category || 'Geral',
       product.description, product.barcode]
    );
    
    // Se for prato, inserir receita
    if (product.type === 'prato' && product.recipe && product.recipe.length > 0) {
      for (let item of product.recipe) {
        await db.promise().query(
          'INSERT INTO product_recipes (product_id, ingredient_id, quantity) VALUES (?, ?, ?)',
          [productId, item.ingredientId, item.quantity]
        );
      }
    }
    
    res.json({ success: true, productId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- FORNECEDORES ---
app.post('/api/suppliers', async (req, res) => {
  try {
    const supplier = req.body;
    const supplierId = `sup_${Date.now()}`;
    
    await db.promise().query(
      `INSERT INTO suppliers (id, name, contact, email, cnpj, address, city, state)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [supplierId, supplier.name, supplier.contact, supplier.email, supplier.cnpj, supplier.address, supplier.city, supplier.state]
    );
    
    res.json({ success: true, supplierId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- CLIENTES ---
app.get('/api/customers', async (req, res) => {
  try {
    const [customers] = await db.promise().query('SELECT * FROM customers ORDER BY nome');
    res.json(customers);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/customers', async (req, res) => {
  try {
    const { nome, sobrenome, fone } = req.body;
    const customerId = `customer_${Date.now()}`;
    
    await db.promise().query(
      `INSERT INTO customers (id, nome, sobrenome, fone) VALUES (?, ?, ?, ?)`,
      [customerId, nome, sobrenome, fone]
    );
    
    res.json({ success: true, customerId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/customers/:id', async (req, res) => {
  try {
    await db.promise().query('DELETE FROM customers WHERE id = ?', [req.params.id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- LISTA DE COMPRAS ---
app.post('/api/shopping-list', async (req, res) => {
  try {
    const { productId, quantity, priority = 'medium', notes } = req.body;
    const itemId = `shop_${Date.now()}`;
    
    await db.promise().query(
      'INSERT INTO shopping_list (id, product_id, quantity, priority, notes) VALUES (?, ?, ?, ?, ?)',
      [itemId, productId, quantity, priority, notes]
    );
    
    res.json({ success: true, itemId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/shopping-list/:id', async (req, res) => {
  try {
    await db.promise().query('DELETE FROM shopping_list WHERE id = ?', [req.params.id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- ATIVOS DIÁRIOS (FINANCEIRO) ---
app.get('/api/daily-assets', async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    let query = 'SELECT * FROM daily_assets';
    let params = [];
    
    if (startDate && endDate) {
      query += ' WHERE date BETWEEN ? AND ?';
      params = [startDate, endDate];
    } else {
      // Últimos 30 dias por padrão
      query += ' WHERE date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)';
    }
    
    query += ' ORDER BY date DESC';
    
    const [assets] = await db.promise().query(query, params);
    res.json(assets);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/daily-assets/today', async (req, res) => {
  try {
    const [assets] = await db.promise().query(
      'SELECT * FROM daily_assets WHERE date = CURDATE()'
    );
    res.json(assets[0] || null);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- DESPESAS ---
app.post('/api/expenses', async (req, res) => {
  try {
    const { date, category, description, amount, paymentMethod, supplierName, invoiceNumber, isRecurring, notes } = req.body;
    const expenseId = `exp_${Date.now()}`;
    
    await db.promise().query(
      `INSERT INTO expenses (id, date, category, description, amount, payment_method, supplier_name, invoice_number, is_recurring, notes)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [expenseId, date, category, description, amount, paymentMethod || 'cash', supplierName, invoiceNumber, isRecurring || false, notes]
    );
    
    res.json({ success: true, expenseId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/expenses', async (req, res) => {
  try {
    const { startDate, endDate, category } = req.query;
    let query = 'SELECT * FROM expenses WHERE 1=1';
    let params = [];
    
    if (startDate && endDate) {
      query += ' AND date BETWEEN ? AND ?';
      params.push(startDate, endDate);
    }
    
    if (category) {
      query += ' AND category = ?';
      params.push(category);
    }
    
    query += ' ORDER BY date DESC';
    
    const [expenses] = await db.promise().query(query, params);
    res.json(expenses);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- CAIXA ---
app.post('/api/cash-register/open', async (req, res) => {
  try {
    const { initialAmount, openedBy } = req.body;
    const registerId = `cash_${Date.now()}`;
    
    await db.promise().query(
      'INSERT INTO cash_register (id, initial_amount, opened_by) VALUES (?, ?, ?)',
      [registerId, initialAmount, openedBy]
    );
    
    res.json({ success: true, registerId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/cash-register/close', async (req, res) => {
  try {
    const { registerId, actualAmount, closedBy, notes } = req.body;
    
    // Chamar stored procedure
    const [result] = await db.promise().query(
      'CALL sp_close_cash_register(?, ?, ?, ?)',
      [registerId, actualAmount, closedBy, notes]
    );
    
    res.json({ success: true, result: result[0][0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/cash-register/current', async (req, res) => {
  try {
    const [registers] = await db.promise().query(
      'SELECT * FROM cash_register WHERE status = "open" ORDER BY opened_at DESC LIMIT 1'
    );
    res.json(registers[0] || null);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/cash-register/history', async (req, res) => {
  try {
    const { days = 30 } = req.query;
    const [registers] = await db.promise().query(
      `SELECT * FROM cash_register 
       WHERE opened_at >= DATE_SUB(NOW(), INTERVAL ? DAY)
       ORDER BY opened_at DESC`,
      [days]
    );
    res.json(registers);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- RELATÓRIOS ---
app.get('/api/reports/monthly', async (req, res) => {
  try {
    const { month, year } = req.query;
    const [result] = await db.promise().query('CALL sp_monthly_report(?, ?)', [month, year]);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/reports/low-stock', async (req, res) => {
  try {
    const [products] = await db.promise().query('SELECT * FROM v_low_stock_products');
    res.json(products);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/reports/production-capacity', async (req, res) => {
  try {
    const [dishes] = await db.promise().query('SELECT * FROM v_dish_production_capacity');
    res.json(dishes);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/reports/best-sellers', async (req, res) => {
  try {
    const [products] = await db.promise().query('SELECT * FROM v_best_selling_products LIMIT 20');
    res.json(products);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/reports/profitability', async (req, res) => {
  try {
    const [products] = await db.promise().query('SELECT * FROM v_product_profitability');
    res.json(products);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- AJUSTE MANUAL DE ESTOQUE ---
app.post('/api/stock/adjust', async (req, res) => {
  try {
    const { productId, newStock, notes, user } = req.body;
    
    const [result] = await db.promise().query(
      'CALL sp_adjust_stock(?, ?, ?, ?)',
      [productId, newStock, notes, user]
    );
    
    res.json({ success: true, result: result[0][0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- HISTÓRICO DE MOVIMENTAÇÕES ---
app.get('/api/stock/movements', async (req, res) => {
  try {
    const { productId, startDate, endDate, limit = 100 } = req.query;
    let query = 'SELECT * FROM stock_movements WHERE 1=1';
    let params = [];
    
    if (productId) {
      query += ' AND product_id = ?';
      params.push(productId);
    }
    
    if (startDate && endDate) {
      query += ' AND created_at BETWEEN ? AND ?';
      params.push(startDate, endDate);
    }
    
    query += ' ORDER BY created_at DESC LIMIT ?';
    params.push(parseInt(limit));
    
    const [movements] = await db.promise().query(query, params);
    res.json(movements);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// =========================================
// INICIAR SERVIDOR
// =========================================

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`[Worker ${process.pid}] Servidor rodando na porta ${PORT}`);
  console.log(`[Worker ${process.pid}] Ambiente: ${process.env.NODE_ENV || 'development'}`);
  console.log(`[Worker ${process.pid}] Banco de dados: ${process.env.DB_NAME || 'lanchonete_db'}`);
});
