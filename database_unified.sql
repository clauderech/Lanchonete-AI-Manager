-- =========================================
-- LANCHONETE AI MANAGER - UNIFIED DATABASE
-- =========================================
-- Sistema Completo de Gestão com Controle Financeiro
-- Combina gestão de lanchonete + controle de ativos
-- =========================================

-- Criar banco de dados
CREATE DATABASE IF NOT EXISTS lanchonete_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE lanchonete_db;

-- =========================================
-- TABELA: suppliers (Fornecedores)
-- =========================================
CREATE TABLE IF NOT EXISTS suppliers (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    contact VARCHAR(100),
    email VARCHAR(255),
    cnpj VARCHAR(18),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_name (name),
    INDEX idx_cnpj (cnpj)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================
-- TABELA: products (Produtos/Insumos)
-- =========================================
CREATE TABLE IF NOT EXISTS products (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type ENUM('insumo', 'prato') NOT NULL COMMENT 'insumo = comprado/estocado, prato = vendido/receita',
    price DECIMAL(10, 2) NOT NULL DEFAULT 0.00 COMMENT 'Preço de venda',
    cost DECIMAL(10, 2) NOT NULL DEFAULT 0.00 COMMENT 'Custo de compra',
    stock DECIMAL(10, 3) NOT NULL DEFAULT 0 COMMENT 'Estoque atual',
    min_stock DECIMAL(10, 3) NOT NULL DEFAULT 10 COMMENT 'Estoque mínimo',
    max_stock DECIMAL(10, 3) DEFAULT NULL COMMENT 'Estoque máximo',
    unit ENUM('un', 'kg', 'g', 'l', 'ml') NOT NULL DEFAULT 'un' COMMENT 'Unidade de medida',
    supplier_id VARCHAR(50),
    category VARCHAR(100) NOT NULL DEFAULT 'Geral',
    description TEXT,
    barcode VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL,
    INDEX idx_type (type),
    INDEX idx_category (category),
    INDEX idx_stock_alert (type, stock, min_stock),
    INDEX idx_supplier (supplier_id),
    INDEX idx_barcode (barcode),
    INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================
-- TABELA: product_recipes (Receitas/Fichas Técnicas)
-- =========================================
CREATE TABLE IF NOT EXISTS product_recipes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id VARCHAR(50) NOT NULL COMMENT 'ID do prato',
    ingredient_id VARCHAR(50) NOT NULL COMMENT 'ID do insumo usado',
    quantity DECIMAL(10, 3) NOT NULL COMMENT 'Quantidade do insumo necessária',
    unit VARCHAR(10) COMMENT 'Unidade de medida na receita',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES products(id) ON DELETE CASCADE,
    UNIQUE KEY unique_recipe_item (product_id, ingredient_id),
    INDEX idx_product (product_id),
    INDEX idx_ingredient (ingredient_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================
-- TABELA: sales (Vendas)
-- =========================================
CREATE TABLE IF NOT EXISTS sales (
    id VARCHAR(50) PRIMARY KEY,
    date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total DECIMAL(10, 2) NOT NULL,
    payment_method ENUM('cash', 'card', 'pix', 'credit') NOT NULL,
    customer_name VARCHAR(255),
    customer_phone VARCHAR(15),
    discount DECIMAL(10, 2) DEFAULT 0.00,
    subtotal DECIMAL(10, 2) NOT NULL COMMENT 'Total antes do desconto',
    comanda_id VARCHAR(50) COMMENT 'ID da comanda se for fechamento de conta',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_date (date),
    INDEX idx_payment (payment_method),
    INDEX idx_customer (customer_name),
    INDEX idx_comanda (comanda_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================
-- TABELA: sale_items (Itens das Vendas)
-- =========================================
CREATE TABLE IF NOT EXISTS sale_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sale_id VARCHAR(50) NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    product_name VARCHAR(255) NOT NULL COMMENT 'Nome no momento da venda',
    quantity DECIMAL(10, 3) NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL COMMENT 'Preço unitário no momento da venda',
    subtotal DECIMAL(10, 2) AS (quantity * unit_price) STORED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    INDEX idx_sale (sale_id),
    INDEX idx_product (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================
-- TABELA: purchases (Compras/Entradas)
-- =========================================
CREATE TABLE IF NOT EXISTS purchases (
    id VARCHAR(50) PRIMARY KEY,
    date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    supplier_id VARCHAR(50) NOT NULL,
    total DECIMAL(10, 2) NOT NULL,
    status ENUM('ordered', 'received', 'cancelled') NOT NULL DEFAULT 'received',
    invoice_number VARCHAR(50),
    payment_method ENUM('cash', 'card', 'transfer', 'check', 'credit') DEFAULT 'cash',
    payment_date DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE RESTRICT,
    INDEX idx_supplier (supplier_id),
    INDEX idx_date (date),
    INDEX idx_status (status),
    INDEX idx_invoice (invoice_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================
-- TABELA: purchase_items (Itens das Compras)
-- =========================================
CREATE TABLE IF NOT EXISTS purchase_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    purchase_id VARCHAR(50) NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    quantity DECIMAL(10, 3) NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL COMMENT 'Custo unitário',
    subtotal DECIMAL(10, 2) AS (quantity * unit_price) STORED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (purchase_id) REFERENCES purchases(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    INDEX idx_purchase (purchase_id),
    INDEX idx_product (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================
-- TABELA: shopping_list (Lista de Compras)
-- =========================================
CREATE TABLE IF NOT EXISTS shopping_list (
    id VARCHAR(50) PRIMARY KEY,
    product_id VARCHAR(50) NOT NULL,
    quantity DECIMAL(10, 3) NOT NULL,
    priority ENUM('low', 'medium', 'high', 'urgent') DEFAULT 'medium',
    is_purchased BOOLEAN DEFAULT FALSE,
    purchased_at TIMESTAMP NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    INDEX idx_product (product_id),
    INDEX idx_purchased (is_purchased),
    INDEX idx_priority (priority)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================
-- TABELA: comandas (Comandas/Contas Abertas)
-- =========================================
CREATE TABLE IF NOT EXISTS comandas (
    id VARCHAR(50) PRIMARY KEY,
    customer_name VARCHAR(255) NOT NULL,
    table_number VARCHAR(20),
    opened_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP NULL,
    total DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    status ENUM('open', 'closed', 'cancelled') NOT NULL DEFAULT 'open',
    payment_method ENUM('cash', 'card', 'pix', 'credit') DEFAULT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_status (status),
    INDEX idx_customer (customer_name),
    INDEX idx_opened_at (opened_at),
    INDEX idx_table (table_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================
-- TABELA: comanda_items (Itens das Comandas)
-- =========================================
CREATE TABLE IF NOT EXISTS comanda_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    comanda_id VARCHAR(50) NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    quantity DECIMAL(10, 3) NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    subtotal DECIMAL(10, 2) AS (quantity * unit_price) STORED,
    status ENUM('pending', 'preparing', 'ready', 'delivered') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (comanda_id) REFERENCES comandas(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    INDEX idx_comanda (comanda_id),
    INDEX idx_product (product_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================
-- TABELA: stock_movements (Histórico de Movimentações)
-- =========================================
CREATE TABLE IF NOT EXISTS stock_movements (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id VARCHAR(50) NOT NULL,
    movement_type ENUM('entrada', 'saida', 'ajuste', 'perda', 'devolucao') NOT NULL,
    quantity DECIMAL(10, 3) NOT NULL,
    previous_stock DECIMAL(10, 3) NOT NULL,
    new_stock DECIMAL(10, 3) NOT NULL,
    reference_type ENUM('sale', 'purchase', 'adjustment', 'recipe', 'loss', 'return') COMMENT 'Tipo de referência',
    reference_id VARCHAR(50) COMMENT 'ID da venda/compra/etc',
    cost_impact DECIMAL(10, 2) DEFAULT 0.00 COMMENT 'Impacto financeiro',
    notes TEXT,
    created_by VARCHAR(100) COMMENT 'Usuário que fez a movimentação',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    INDEX idx_product (product_id),
    INDEX idx_type (movement_type),
    INDEX idx_date (created_at),
    INDEX idx_reference (reference_type, reference_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================
-- NOVA TABELA: daily_assets (Ativos Diários)
-- =========================================
CREATE TABLE IF NOT EXISTS daily_assets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    date DATE NOT NULL UNIQUE,
    total_inicial DECIMAL(10, 2) NOT NULL DEFAULT 0.00 COMMENT 'Saldo inicial do dia',
    total_final DECIMAL(10, 2) NOT NULL DEFAULT 0.00 COMMENT 'Saldo final do dia',
    
    -- Detalhamento de receitas
    sales_cash DECIMAL(10, 2) DEFAULT 0.00,
    sales_card DECIMAL(10, 2) DEFAULT 0.00,
    sales_pix DECIMAL(10, 2) DEFAULT 0.00,
    sales_credit DECIMAL(10, 2) DEFAULT 0.00,
    total_sales DECIMAL(10, 2) AS (sales_cash + sales_card + sales_pix + sales_credit) STORED,
    
    -- Detalhamento de despesas
    purchases_total DECIMAL(10, 2) DEFAULT 0.00,
    expenses_total DECIMAL(10, 2) DEFAULT 0.00,
    losses_total DECIMAL(10, 2) DEFAULT 0.00,
    total_expenses DECIMAL(10, 2) AS (purchases_total + expenses_total + losses_total) STORED,
    
    -- Balanço
    net_balance DECIMAL(10, 2) AS (total_sales - total_expenses) STORED,
    
    -- Contadores
    sales_count INT DEFAULT 0,
    items_sold INT DEFAULT 0,
    average_ticket DECIMAL(10, 2) DEFAULT 0.00,
    
    -- Status
    is_closed BOOLEAN DEFAULT FALSE COMMENT 'Dia fechado/auditado',
    notes TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_date (date),
    INDEX idx_closed (is_closed),
    INDEX idx_month (date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================
-- NOVA TABELA: expenses (Despesas Operacionais)
-- =========================================
CREATE TABLE IF NOT EXISTS expenses (
    id VARCHAR(50) PRIMARY KEY,
    date DATE NOT NULL,
    category ENUM('salarios', 'aluguel', 'energia', 'agua', 'gas', 'telefone', 'manutencao', 'impostos', 'outros') NOT NULL,
    description VARCHAR(255) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    payment_method ENUM('cash', 'card', 'transfer', 'check') DEFAULT 'cash',
    supplier_name VARCHAR(255),
    invoice_number VARCHAR(50),
    is_recurring BOOLEAN DEFAULT FALSE COMMENT 'Despesa recorrente',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_date (date),
    INDEX idx_category (category),
    INDEX idx_recurring (is_recurring)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================
-- NOVA TABELA: cash_register (Caixa)
-- =========================================
CREATE TABLE IF NOT EXISTS cash_register (
    id VARCHAR(50) PRIMARY KEY,
    opened_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP NULL,
    opened_by VARCHAR(100) NOT NULL COMMENT 'Operador que abriu',
    closed_by VARCHAR(100) COMMENT 'Operador que fechou',
    
    initial_amount DECIMAL(10, 2) NOT NULL COMMENT 'Valor inicial (troco)',
    expected_amount DECIMAL(10, 2) DEFAULT 0.00 COMMENT 'Valor esperado',
    actual_amount DECIMAL(10, 2) DEFAULT 0.00 COMMENT 'Valor contado',
    difference DECIMAL(10, 2) AS (actual_amount - expected_amount) STORED,
    
    status ENUM('open', 'closed') DEFAULT 'open',
    notes TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_status (status),
    INDEX idx_date (opened_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================
-- TRIGGERS: Atualizar estoque automaticamente
-- =========================================

DELIMITER $$

-- Trigger: Baixar estoque ao adicionar venda
CREATE TRIGGER after_sale_item_insert 
AFTER INSERT ON sale_items
FOR EACH ROW
BEGIN
    DECLARE v_type VARCHAR(10);
    DECLARE v_stock DECIMAL(10,3);
    DECLARE v_cost DECIMAL(10,2);
    
    SELECT type, stock, cost INTO v_type, v_stock, v_cost FROM products WHERE id = NEW.product_id;
    
    IF v_type = 'prato' THEN
        -- Baixar ingredientes da receita
        UPDATE products p
        INNER JOIN product_recipes pr ON p.id = pr.ingredient_id
        SET p.stock = p.stock - (pr.quantity * NEW.quantity)
        WHERE pr.product_id = NEW.product_id;
        
        -- Registrar movimentações
        INSERT INTO stock_movements (product_id, movement_type, quantity, previous_stock, new_stock, reference_type, reference_id, cost_impact, notes)
        SELECT 
            pr.ingredient_id,
            'saida',
            pr.quantity * NEW.quantity,
            p.stock + (pr.quantity * NEW.quantity),
            p.stock,
            'sale',
            NEW.sale_id,
            -(pr.quantity * NEW.quantity * p.cost),
            CONCAT('Venda de ', NEW.product_name)
        FROM product_recipes pr
        INNER JOIN products p ON p.id = pr.ingredient_id
        WHERE pr.product_id = NEW.product_id;
        
    ELSEIF v_type = 'insumo' THEN
        UPDATE products SET stock = stock - NEW.quantity WHERE id = NEW.product_id;
        
        INSERT INTO stock_movements (product_id, movement_type, quantity, previous_stock, new_stock, reference_type, reference_id, cost_impact)
        VALUES (NEW.product_id, 'saida', NEW.quantity, v_stock, v_stock - NEW.quantity, 'sale', NEW.sale_id, -(NEW.quantity * v_cost));
    END IF;
END$$

-- Trigger: Adicionar estoque ao receber compra
CREATE TRIGGER after_purchase_item_insert 
AFTER INSERT ON purchase_items
FOR EACH ROW
BEGIN
    DECLARE v_stock DECIMAL(10,3);
    
    SELECT stock INTO v_stock FROM products WHERE id = NEW.product_id;
    
    UPDATE products 
    SET stock = stock + NEW.quantity,
        cost = NEW.unit_price
    WHERE id = NEW.product_id;
    
    INSERT INTO stock_movements (product_id, movement_type, quantity, previous_stock, new_stock, reference_type, reference_id, cost_impact)
    VALUES (NEW.product_id, 'entrada', NEW.quantity, v_stock, v_stock + NEW.quantity, 'purchase', NEW.purchase_id, NEW.subtotal);
END$$

-- Trigger: Atualizar daily_assets ao adicionar venda
CREATE TRIGGER after_sale_insert
AFTER INSERT ON sales
FOR EACH ROW
BEGIN
    DECLARE v_initial DECIMAL(10,2);
    DECLARE v_sales_count INT;
    DECLARE v_items_count INT;
    
    -- Buscar saldo inicial (do dia anterior)
    SELECT COALESCE(total_final, 0) INTO v_initial 
    FROM daily_assets 
    WHERE date = DATE(NEW.date) - INTERVAL 1 DAY
    LIMIT 1;
    
    -- Contar vendas e itens do dia
    SELECT COUNT(*), COALESCE(SUM(total), 0) 
    INTO v_sales_count, @sales_total
    FROM sales 
    WHERE DATE(date) = DATE(NEW.date);
    
    SELECT COALESCE(SUM(quantity), 0) 
    INTO v_items_count
    FROM sale_items si
    INNER JOIN sales s ON si.sale_id = s.id
    WHERE DATE(s.date) = DATE(NEW.date);
    
    -- Inserir ou atualizar daily_assets
    INSERT INTO daily_assets (
        date, 
        total_inicial, 
        total_final,
        sales_cash,
        sales_card,
        sales_pix,
        sales_credit,
        sales_count,
        items_sold,
        average_ticket
    ) VALUES (
        DATE(NEW.date),
        v_initial,
        v_initial + NEW.total,
        CASE WHEN NEW.payment_method = 'cash' THEN NEW.total ELSE 0 END,
        CASE WHEN NEW.payment_method = 'card' THEN NEW.total ELSE 0 END,
        CASE WHEN NEW.payment_method = 'pix' THEN NEW.total ELSE 0 END,
        CASE WHEN NEW.payment_method = 'credit' THEN NEW.total ELSE 0 END,
        1,
        v_items_count,
        NEW.total
    ) ON DUPLICATE KEY UPDATE
        total_final = total_final + NEW.total,
        sales_cash = sales_cash + CASE WHEN NEW.payment_method = 'cash' THEN NEW.total ELSE 0 END,
        sales_card = sales_card + CASE WHEN NEW.payment_method = 'card' THEN NEW.total ELSE 0 END,
        sales_pix = sales_pix + CASE WHEN NEW.payment_method = 'pix' THEN NEW.total ELSE 0 END,
        sales_credit = sales_credit + CASE WHEN NEW.payment_method = 'credit' THEN NEW.total ELSE 0 END,
        sales_count = sales_count + 1,
        items_sold = v_items_count,
        average_ticket = total_sales / sales_count;
END$$

-- Trigger: Atualizar daily_assets ao adicionar compra
CREATE TRIGGER after_purchase_insert
AFTER INSERT ON purchases
FOR EACH ROW
BEGIN
    IF NEW.status = 'received' THEN
        INSERT INTO daily_assets (date, total_inicial, total_final, purchases_total)
        SELECT 
            DATE(NEW.date),
            COALESCE((SELECT total_final FROM daily_assets WHERE date = DATE(NEW.date) - INTERVAL 1 DAY LIMIT 1), 0),
            COALESCE((SELECT total_final FROM daily_assets WHERE date = DATE(NEW.date) - INTERVAL 1 DAY LIMIT 1), 0) - NEW.total,
            NEW.total
        ON DUPLICATE KEY UPDATE
            total_final = total_final - NEW.total,
            purchases_total = purchases_total + NEW.total;
    END IF;
END$$

-- Trigger: Atualizar daily_assets ao adicionar despesa
CREATE TRIGGER after_expense_insert
AFTER INSERT ON expenses
FOR EACH ROW
BEGIN
    INSERT INTO daily_assets (date, total_inicial, total_final, expenses_total)
    SELECT 
        NEW.date,
        COALESCE((SELECT total_final FROM daily_assets WHERE date = NEW.date - INTERVAL 1 DAY LIMIT 1), 0),
        COALESCE((SELECT total_final FROM daily_assets WHERE date = NEW.date - INTERVAL 1 DAY LIMIT 1), 0) - NEW.amount,
        NEW.amount
    ON DUPLICATE KEY UPDATE
        total_final = total_final - NEW.amount,
        expenses_total = expenses_total + NEW.amount;
END$$

DELIMITER ;

-- =========================================
-- VIEWS EXPANDIDAS
-- =========================================

-- View: Produtos com estoque baixo (expandida)
CREATE OR REPLACE VIEW v_low_stock_products AS
SELECT 
    p.id,
    p.name,
    p.stock,
    p.min_stock,
    p.max_stock,
    p.unit,
    p.category,
    p.cost,
    s.name AS supplier_name,
    s.contact AS supplier_contact,
    s.email AS supplier_email,
    (p.min_stock * 2 - p.stock) AS suggested_order_qty,
    ((p.min_stock * 2 - p.stock) * p.cost) AS estimated_cost,
    CASE 
        WHEN p.stock <= 0 THEN 'CRÍTICO'
        WHEN p.stock <= (p.min_stock * 0.5) THEN 'URGENTE'
        WHEN p.stock <= p.min_stock THEN 'BAIXO'
        ELSE 'NORMAL'
    END AS alert_level
FROM products p
LEFT JOIN suppliers s ON p.supplier_id = s.id
WHERE p.type = 'insumo' 
  AND p.stock <= p.min_stock 
  AND p.is_active = TRUE
ORDER BY 
    CASE 
        WHEN p.stock <= 0 THEN 1
        WHEN p.stock <= (p.min_stock * 0.5) THEN 2
        WHEN p.stock <= p.min_stock THEN 3
    END,
    p.stock / NULLIF(p.min_stock, 0) ASC;

-- View: Capacidade de produção expandida
CREATE OR REPLACE VIEW v_dish_production_capacity AS
SELECT 
    p.id,
    p.name,
    p.price,
    p.cost AS dish_cost,
    p.category,
    MIN(FLOOR(ing.stock / pr.quantity)) AS max_producible,
    COUNT(pr.ingredient_id) AS ingredients_count,
    SUM(CASE WHEN ing.stock <= ing.min_stock THEN 1 ELSE 0 END) AS low_stock_ingredients,
    (p.price - p.cost) AS profit_per_unit,
    (p.price - p.cost) * MIN(FLOOR(ing.stock / pr.quantity)) AS potential_profit
FROM products p
INNER JOIN product_recipes pr ON p.id = pr.product_id
INNER JOIN products ing ON pr.ingredient_id = ing.id
WHERE p.type = 'prato' AND p.is_active = TRUE
GROUP BY p.id, p.name, p.price, p.cost, p.category
ORDER BY max_producible ASC;

-- View: Dashboard financeiro diário
CREATE OR REPLACE VIEW v_daily_financial_dashboard AS
SELECT 
    da.date,
    da.total_inicial,
    da.total_final,
    da.sales_cash,
    da.sales_card,
    da.sales_pix,
    da.sales_credit,
    da.total_sales,
    da.purchases_total,
    da.expenses_total,
    da.losses_total,
    da.total_expenses,
    da.net_balance,
    da.sales_count,
    da.items_sold,
    da.average_ticket,
    da.is_closed,
    CASE 
        WHEN da.net_balance > 0 THEN 'LUCRO'
        WHEN da.net_balance < 0 THEN 'PREJUÍZO'
        ELSE 'NEUTRO'
    END AS status,
    ROUND((da.net_balance / NULLIF(da.total_sales, 0)) * 100, 2) AS profit_margin_percent
FROM daily_assets da
ORDER BY da.date DESC;

-- View: Vendas do dia expandida
CREATE OR REPLACE VIEW v_today_sales AS
SELECT 
    s.id,
    s.date,
    s.total,
    s.subtotal,
    s.discount,
    s.payment_method,
    s.customer_name,
    s.customer_phone,
    COUNT(si.id) AS items_count,
    GROUP_CONCAT(CONCAT(si.product_name, ' (', si.quantity, ')') SEPARATOR ', ') AS items_summary
FROM sales s
LEFT JOIN sale_items si ON s.id = si.sale_id
WHERE DATE(s.date) = CURDATE()
GROUP BY s.id, s.date, s.total, s.subtotal, s.discount, s.payment_method, s.customer_name, s.customer_phone
ORDER BY s.date DESC;

-- View: Resumo de vendas por período (expandido)
CREATE OR REPLACE VIEW v_sales_summary AS
SELECT 
    DATE(s.date) AS sale_date,
    DAYNAME(s.date) AS day_of_week,
    COUNT(DISTINCT s.id) AS total_sales,
    SUM(s.total) AS total_revenue,
    SUM(s.subtotal) AS subtotal_before_discount,
    SUM(s.discount) AS total_discounts,
    AVG(s.total) AS average_ticket,
    MAX(s.total) AS highest_sale,
    MIN(s.total) AS lowest_sale,
    SUM(CASE WHEN s.payment_method = 'cash' THEN s.total ELSE 0 END) AS cash_total,
    SUM(CASE WHEN s.payment_method = 'card' THEN s.total ELSE 0 END) AS card_total,
    SUM(CASE WHEN s.payment_method = 'pix' THEN s.total ELSE 0 END) AS pix_total,
    SUM(CASE WHEN s.payment_method = 'credit' THEN s.total ELSE 0 END) AS credit_total,
    SUM(si.quantity) AS total_items_sold
FROM sales s
LEFT JOIN sale_items si ON s.id = si.sale_id
GROUP BY DATE(s.date), DAYNAME(s.date)
ORDER BY sale_date DESC;

-- View: Produtos mais vendidos (expandido)
CREATE OR REPLACE VIEW v_best_selling_products AS
SELECT 
    p.id,
    p.name,
    p.type,
    p.category,
    p.price AS current_price,
    SUM(si.quantity) AS total_sold,
    COUNT(DISTINCT si.sale_id) AS sales_count,
    SUM(si.subtotal) AS total_revenue,
    AVG(si.unit_price) AS average_selling_price,
    MAX(DATE(s.date)) AS last_sold_date,
    DATEDIFF(CURDATE(), MAX(DATE(s.date))) AS days_since_last_sale
FROM sale_items si
INNER JOIN products p ON si.product_id = p.id
INNER JOIN sales s ON si.sale_id = s.id
GROUP BY p.id, p.name, p.type, p.category, p.price
ORDER BY total_sold DESC;

-- View: Comandas abertas
CREATE OR REPLACE VIEW v_open_comandas AS
SELECT 
    c.id,
    c.customer_name,
    c.table_number,
    c.opened_at,
    c.total,
    COUNT(ci.id) AS items_count,
    TIMESTAMPDIFF(MINUTE, c.opened_at, NOW()) AS minutes_open,
    GROUP_CONCAT(CONCAT(ci.product_name, ' (', ci.quantity, ')') SEPARATOR ', ') AS items_summary
FROM comandas c
LEFT JOIN comanda_items ci ON c.id = ci.comanda_id
WHERE c.status = 'open'
GROUP BY c.id, c.customer_name, c.table_number, c.opened_at, c.total
ORDER BY c.opened_at DESC;

-- View: Análise de lucratividade por produto
CREATE OR REPLACE VIEW v_product_profitability AS
SELECT 
    p.id,
    p.name,
    p.type,
    p.category,
    p.price AS selling_price,
    p.cost AS product_cost,
    (p.price - p.cost) AS profit_per_unit,
    ROUND(((p.price - p.cost) / NULLIF(p.price, 0)) * 100, 2) AS profit_margin_percent,
    COALESCE(SUM(si.quantity), 0) AS units_sold_30d,
    COALESCE(SUM(si.subtotal), 0) AS revenue_30d,
    COALESCE(SUM(si.quantity) * p.cost, 0) AS cost_30d,
    COALESCE(SUM(si.subtotal) - (SUM(si.quantity) * p.cost), 0) AS profit_30d
FROM products p
LEFT JOIN sale_items si ON p.id = si.product_id
LEFT JOIN sales s ON si.sale_id = s.id AND s.date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
WHERE p.type = 'prato' AND p.is_active = TRUE
GROUP BY p.id, p.name, p.type, p.category, p.price, p.cost
ORDER BY profit_30d DESC;

-- =========================================
-- STORED PROCEDURES EXPANDIDAS
-- =========================================

DELIMITER $$

-- Procedure: Calcular custo real de um prato (expandida)
CREATE PROCEDURE sp_calculate_dish_cost(IN p_dish_id VARCHAR(50))
BEGIN
    SELECT 
        p.id,
        p.name AS dish_name,
        p.category,
        SUM(ing.cost * pr.quantity) AS total_cost,
        p.price AS selling_price,
        p.price - SUM(ing.cost * pr.quantity) AS profit_margin,
        ROUND(((p.price - SUM(ing.cost * pr.quantity)) / NULLIF(p.price, 0) * 100), 2) AS profit_percentage,
        COUNT(pr.ingredient_id) AS ingredients_count,
        MIN(FLOOR(ing.stock / pr.quantity)) AS max_producible
    FROM products p
    INNER JOIN product_recipes pr ON p.id = pr.product_id
    INNER JOIN products ing ON pr.ingredient_id = ing.id
    WHERE p.id = p_dish_id AND p.type = 'prato'
    GROUP BY p.id, p.name, p.category, p.price;
END$$

-- Procedure: Listar ingredientes de um prato (expandida)
CREATE PROCEDURE sp_get_dish_recipe(IN p_dish_id VARCHAR(50))
BEGIN
    SELECT 
        pr.ingredient_id,
        ing.name AS ingredient_name,
        pr.quantity,
        ing.unit,
        ing.stock AS available_stock,
        FLOOR(ing.stock / pr.quantity) AS portions_available,
        ing.cost AS unit_cost,
        (pr.quantity * ing.cost) AS ingredient_cost,
        CASE 
            WHEN ing.stock < pr.quantity THEN 'INSUFICIENTE'
            WHEN ing.stock <= ing.min_stock THEN 'BAIXO'
            ELSE 'OK'
        END AS stock_status
    FROM product_recipes pr
    INNER JOIN products ing ON pr.ingredient_id = ing.id
    WHERE pr.product_id = p_dish_id
    ORDER BY ing.name;
END$$

-- Procedure: Fechamento de caixa
CREATE PROCEDURE sp_close_cash_register(
    IN p_register_id VARCHAR(50),
    IN p_actual_amount DECIMAL(10,2),
    IN p_closed_by VARCHAR(100),
    IN p_notes TEXT
)
BEGIN
    DECLARE v_expected DECIMAL(10,2);
    
    -- Calcular valor esperado
    SELECT 
        cr.initial_amount + COALESCE(SUM(s.total), 0)
    INTO v_expected
    FROM cash_register cr
    LEFT JOIN sales s ON s.payment_method = 'cash' 
        AND s.date >= cr.opened_at 
        AND s.date <= COALESCE(cr.closed_at, NOW())
    WHERE cr.id = p_register_id
    GROUP BY cr.initial_amount;
    
    -- Atualizar registro
    UPDATE cash_register
    SET 
        closed_at = NOW(),
        closed_by = p_closed_by,
        expected_amount = v_expected,
        actual_amount = p_actual_amount,
        status = 'closed',
        notes = p_notes
    WHERE id = p_register_id;
    
    -- Retornar resumo
    SELECT 
        id,
        opened_at,
        closed_at,
        initial_amount,
        expected_amount,
        actual_amount,
        difference,
        opened_by,
        closed_by
    FROM cash_register
    WHERE id = p_register_id;
END$$

-- Procedure: Relatório mensal completo
CREATE PROCEDURE sp_monthly_report(IN p_month INT, IN p_year INT)
BEGIN
    DECLARE v_start_date DATE;
    DECLARE v_end_date DATE;
    
    SET v_start_date = STR_TO_DATE(CONCAT(p_year, '-', p_month, '-01'), '%Y-%m-%d');
    SET v_end_date = LAST_DAY(v_start_date);
    
    -- Resumo geral
    SELECT 
        'RESUMO MENSAL' AS section,
        SUM(total_sales) AS total_revenue,
        SUM(purchases_total) AS total_purchases,
        SUM(expenses_total) AS total_expenses,
        SUM(net_balance) AS net_profit,
        AVG(average_ticket) AS avg_ticket,
        SUM(sales_count) AS total_transactions,
        SUM(items_sold) AS total_items
    FROM daily_assets
    WHERE date BETWEEN v_start_date AND v_end_date;
    
    -- Por forma de pagamento
    SELECT 
        'PAGAMENTOS' AS section,
        SUM(sales_cash) AS cash,
        SUM(sales_card) AS card,
        SUM(sales_pix) AS pix,
        SUM(sales_credit) AS credit
    FROM daily_assets
    WHERE date BETWEEN v_start_date AND v_end_date;
    
    -- Top 10 produtos
    SELECT 
        'TOP PRODUTOS' AS section,
        p.name,
        SUM(si.quantity) AS qty_sold,
        SUM(si.subtotal) AS revenue
    FROM sale_items si
    INNER JOIN sales s ON si.sale_id = s.id
    INNER JOIN products p ON si.product_id = p.id
    WHERE DATE(s.date) BETWEEN v_start_date AND v_end_date
    GROUP BY p.id, p.name
    ORDER BY revenue DESC
    LIMIT 10;
END$$

-- Procedure: Ajuste manual de estoque
CREATE PROCEDURE sp_adjust_stock(
    IN p_product_id VARCHAR(50),
    IN p_new_stock DECIMAL(10,3),
    IN p_notes TEXT,
    IN p_user VARCHAR(100)
)
BEGIN
    DECLARE v_current_stock DECIMAL(10,3);
    DECLARE v_cost DECIMAL(10,2);
    DECLARE v_diff DECIMAL(10,3);
    
    SELECT stock, cost INTO v_current_stock, v_cost FROM products WHERE id = p_product_id;
    SET v_diff = p_new_stock - v_current_stock;
    
    UPDATE products SET stock = p_new_stock WHERE id = p_product_id;
    
    INSERT INTO stock_movements (
        product_id, 
        movement_type, 
        quantity, 
        previous_stock, 
        new_stock, 
        reference_type, 
        cost_impact,
        notes,
        created_by
    ) VALUES (
        p_product_id,
        'ajuste',
        ABS(v_diff),
        v_current_stock,
        p_new_stock,
        'adjustment',
        v_diff * v_cost,
        p_notes,
        p_user
    );
    
    SELECT 'Estoque ajustado com sucesso' AS message, v_current_stock AS old_stock, p_new_stock AS new_stock, v_diff AS difference;
END$$

DELIMITER ;

-- =========================================
-- DADOS INICIAIS (SEED DATA) - Mantidos do database.sql
-- =========================================

-- Fornecedores
INSERT INTO suppliers (id, name, contact, email, cnpj, address, city, state) VALUES
('sup_001', 'Distribuidora Alimentos Ltda', '(11) 98765-4321', 'contato@distribuidoraalimentos.com.br', '12.345.678/0001-90', 'Rua das Flores, 123', 'São Paulo', 'SP'),
('sup_002', 'Açougue Bom Preço', '(11) 99876-5432', 'vendas@acouguebompreco.com.br', '23.456.789/0001-01', 'Av. Principal, 456', 'São Paulo', 'SP'),
('sup_003', 'Hortifruti Verde Vida', '(11) 97654-3210', 'pedidos@verdevida.com.br', '34.567.890/0001-12', 'Rua do Mercado, 789', 'São Paulo', 'SP'),
('sup_004', 'Bebidas Express', '(11) 96543-2109', 'comercial@bebidasexpress.com.br', '45.678.901/0001-23', 'Av. Distribuidores, 321', 'São Paulo', 'SP');

-- Insumos
INSERT INTO products (id, name, type, price, cost, stock, min_stock, max_stock, unit, supplier_id, category, barcode) VALUES
-- Carnes
('ing_001', 'Carne Moída Bovina', 'insumo', 0, 25.00, 5.5, 2.0, 15.0, 'kg', 'sup_002', 'Carnes', '7891234500001'),
('ing_002', 'Peito de Frango', 'insumo', 0, 18.00, 8.0, 3.0, 20.0, 'kg', 'sup_002', 'Carnes', '7891234500002'),
('ing_003', 'Bacon em Tiras', 'insumo', 0, 32.00, 2.5, 1.0, 10.0, 'kg', 'sup_002', 'Carnes', '7891234500003'),
('ing_004', 'Linguiça Calabresa', 'insumo', 0, 22.00, 4.0, 2.0, 12.0, 'kg', 'sup_002', 'Carnes', '7891234500004'),

-- Pães
('ing_005', 'Pão de Hambúrguer', 'insumo', 0, 0.80, 150, 50, 300, 'un', 'sup_001', 'Pães', '7891234500005'),
('ing_006', 'Pão Francês', 'insumo', 0, 0.50, 200, 100, 400, 'un', 'sup_001', 'Pães', '7891234500006'),
('ing_007', 'Pão de Hot Dog', 'insumo', 0, 0.70, 120, 40, 250, 'un', 'sup_001', 'Pães', '7891234500007'),

-- Laticínios
('ing_008', 'Queijo Mussarela Fatiado', 'insumo', 0, 35.00, 3.0, 1.5, 10.0, 'kg', 'sup_001', 'Laticínios', '7891234500008'),
('ing_009', 'Queijo Cheddar', 'insumo', 0, 42.00, 2.0, 1.0, 8.0, 'kg', 'sup_001', 'Laticínios', '7891234500009'),
('ing_010', 'Requeijão Cremoso', 'insumo', 0, 18.00, 4, 2, 10, 'un', 'sup_001', 'Laticínios', '7891234500010'),

-- Vegetais
('ing_011', 'Alface Americana', 'insumo', 0, 3.50, 20, 10, 40, 'un', 'sup_003', 'Vegetais', '7891234500011'),
('ing_012', 'Tomate', 'insumo', 0, 4.50, 15, 8, 30, 'kg', 'sup_003', 'Vegetais', '7891234500012'),
('ing_013', 'Cebola', 'insumo', 0, 3.00, 12, 5, 25, 'kg', 'sup_003', 'Vegetais', '7891234500013'),
('ing_014', 'Batata Palito Congelada', 'insumo', 0, 12.00, 25, 10, 50, 'kg', 'sup_001', 'Vegetais', '7891234500014'),

-- Condimentos
('ing_015', 'Maionese', 'insumo', 0, 8.50, 10, 5, 20, 'un', 'sup_001', 'Condimentos', '7891234500015'),
('ing_016', 'Ketchup', 'insumo', 0, 7.00, 12, 5, 20, 'un', 'sup_001', 'Condimentos', '7891234500016'),
('ing_017', 'Mostarda', 'insumo', 0, 6.50, 10, 4, 15, 'un', 'sup_001', 'Condimentos', '7891234500017'),
('ing_018', 'Molho Barbecue', 'insumo', 0, 9.00, 8, 3, 15, 'un', 'sup_001', 'Condimentos', '7891234500018'),

-- Bebidas
('ing_019', 'Refrigerante Lata 350ml', 'insumo', 0, 2.50, 100, 50, 200, 'un', 'sup_004', 'Bebidas', '7891234500019'),
('ing_020', 'Suco Natural Laranja (500ml)', 'insumo', 0, 3.00, 30, 15, 60, 'un', 'sup_004', 'Bebidas', '7891234500020'),
('ing_021', 'Água Mineral 500ml', 'insumo', 0, 1.20, 80, 40, 150, 'un', 'sup_004', 'Bebidas', '7891234500021'),

-- Outros
('ing_022', 'Óleo de Soja', 'insumo', 0, 8.00, 15, 5, 30, 'l', 'sup_001', 'Diversos', '7891234500022'),
('ing_023', 'Sal Refinado', 'insumo', 0, 2.00, 20, 8, 40, 'kg', 'sup_001', 'Diversos', '7891234500023');

-- Pratos
INSERT INTO products (id, name, type, price, cost, stock, min_stock, unit, category) VALUES
('dish_001', 'X-Burger Clássico', 'prato', 18.00, 7.50, 0, 0, 'un', 'Hambúrguers'),
('dish_002', 'X-Bacon Especial', 'prato', 22.00, 9.80, 0, 0, 'un', 'Hambúrguers'),
('dish_003', 'X-Tudo Completo', 'prato', 28.00, 13.50, 0, 0, 'un', 'Hambúrguers'),
('dish_004', 'X-Frango Grill', 'prato', 20.00, 8.20, 0, 0, 'un', 'Hambúrguers'),
('dish_005', 'Hot Dog Tradicional', 'prato', 12.00, 5.00, 0, 0, 'un', 'Lanches'),
('dish_006', 'Misto Quente', 'prato', 10.00, 3.80, 0, 0, 'un', 'Lanches'),
('dish_007', 'Batata Frita Grande', 'prato', 15.00, 6.00, 0, 0, 'un', 'Porções'),
('dish_008', 'Refrigerante Lata', 'prato', 5.00, 2.50, 0, 0, 'un', 'Bebidas'),
('dish_009', 'Suco Natural Laranja', 'prato', 8.00, 3.00, 0, 0, 'un', 'Bebidas'),
('dish_010', 'Água Mineral', 'prato', 3.00, 1.20, 0, 0, 'un', 'Bebidas');

-- Receitas (mantidas do database.sql original)
INSERT INTO product_recipes (product_id, ingredient_id, quantity) VALUES
('dish_001', 'ing_005', 1), ('dish_001', 'ing_001', 0.15), ('dish_001', 'ing_008', 0.03),
('dish_001', 'ing_011', 0.05), ('dish_001', 'ing_012', 0.03), ('dish_001', 'ing_015', 0.02), ('dish_001', 'ing_016', 0.02),
('dish_002', 'ing_005', 1), ('dish_002', 'ing_001', 0.15), ('dish_002', 'ing_008', 0.03),
('dish_002', 'ing_003', 0.05), ('dish_002', 'ing_011', 0.05), ('dish_002', 'ing_012', 0.03), ('dish_002', 'ing_015', 0.02),
('dish_003', 'ing_005', 1), ('dish_003', 'ing_001', 0.15), ('dish_003', 'ing_008', 0.03),
('dish_003', 'ing_003', 0.05), ('dish_003', 'ing_009', 0.02), ('dish_003', 'ing_004', 0.05),
('dish_003', 'ing_011', 0.05), ('dish_003', 'ing_012', 0.03), ('dish_003', 'ing_013', 0.02),
('dish_003', 'ing_015', 0.02), ('dish_003', 'ing_016', 0.02),
('dish_004', 'ing_005', 1), ('dish_004', 'ing_002', 0.15), ('dish_004', 'ing_008', 0.03),
('dish_004', 'ing_011', 0.05), ('dish_004', 'ing_012', 0.03), ('dish_004', 'ing_015', 0.02),
('dish_005', 'ing_007', 1), ('dish_005', 'ing_004', 0.10), ('dish_005', 'ing_015', 0.02),
('dish_005', 'ing_016', 0.02), ('dish_005', 'ing_017', 0.01), ('dish_005', 'ing_010', 0.02),
('dish_006', 'ing_006', 1), ('dish_006', 'ing_008', 0.03),
('dish_007', 'ing_014', 0.40), ('dish_007', 'ing_022', 0.10),
('dish_008', 'ing_019', 1),
('dish_009', 'ing_020', 1),
('dish_010', 'ing_021', 1);

-- Seed para daily_assets (últimos 7 dias)
INSERT INTO daily_assets (date, total_inicial, total_final, sales_cash, sales_card, sales_pix, sales_count, items_sold, average_ticket) VALUES
(DATE_SUB(CURDATE(), INTERVAL 7 DAY), 10000.00, 10850.50, 450.00, 300.50, 100.00, 12, 35, 70.87),
(DATE_SUB(CURDATE(), INTERVAL 6 DAY), 10850.50, 11420.30, 380.00, 189.80, 0.00, 9, 24, 63.31),
(DATE_SUB(CURDATE(), INTERVAL 5 DAY), 11420.30, 12105.80, 520.00, 165.50, 0.00, 15, 42, 45.70),
(DATE_SUB(CURDATE(), INTERVAL 4 DAY), 12105.80, 12890.20, 640.00, 144.40, 0.00, 18, 51, 43.58),
(DATE_SUB(CURDATE(), INTERVAL 3 DAY), 12890.20, 13650.70, 590.00, 170.50, 0.00, 16, 47, 47.53),
(DATE_SUB(CURDATE(), INTERVAL 2 DAY), 13650.70, 14420.30, 610.00, 159.60, 0.00, 17, 49, 45.27),
(DATE_SUB(CURDATE(), INTERVAL 1 DAY), 14420.30, 15280.80, 720.00, 140.50, 0.00, 20, 58, 43.03);

-- =========================================
-- ÍNDICES ADICIONAIS PARA PERFORMANCE
-- =========================================

CREATE INDEX idx_products_type_active ON products(type, is_active);
CREATE INDEX idx_sales_date_payment ON sales(date, payment_method);
CREATE INDEX idx_movements_product_date ON stock_movements(product_id, created_at);
CREATE INDEX idx_daily_assets_month ON daily_assets(date);
CREATE INDEX idx_expenses_date_category ON expenses(date, category);

-- =========================================
-- INFORMAÇÕES FINAIS
-- =========================================

SELECT '✅ Database Unified created successfully!' AS status;
SELECT COUNT(*) AS total_suppliers FROM suppliers;
SELECT COUNT(*) AS total_products FROM products;
SELECT COUNT(*) AS total_ingredients FROM products WHERE type = 'insumo';
SELECT COUNT(*) AS total_dishes FROM products WHERE type = 'prato';
SELECT COUNT(*) AS total_recipes FROM product_recipes;
SELECT 'Nova feature: Daily Assets tracking enabled!' AS info;
SELECT 'Nova feature: Cash Register management enabled!' AS info;
SELECT 'Nova feature: Expenses tracking enabled!' AS info;

-- =========================================
-- FIM DO SCRIPT
-- =========================================