-- =========================================
-- LANCHONETE AI MANAGER - DATABASE SCHEMA
-- =========================================
-- Sistema de Gestão de Lanchonete com IA
-- Estrutura completa de banco de dados MySQL
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
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_name (name)
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
    unit ENUM('un', 'kg', 'g', 'l', 'ml') NOT NULL DEFAULT 'un' COMMENT 'Unidade de medida',
    supplier_id VARCHAR(50),
    category VARCHAR(100) NOT NULL DEFAULT 'Geral',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL,
    INDEX idx_type (type),
    INDEX idx_category (category),
    INDEX idx_stock_alert (type, stock, min_stock),
    INDEX idx_supplier (supplier_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================
-- TABELA: product_recipes (Receitas/Fichas Técnicas)
-- =========================================
CREATE TABLE IF NOT EXISTS product_recipes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id VARCHAR(50) NOT NULL COMMENT 'ID do prato',
    ingredient_id VARCHAR(50) NOT NULL COMMENT 'ID do insumo usado',
    quantity DECIMAL(10, 3) NOT NULL COMMENT 'Quantidade do insumo necessária',
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
    payment_method ENUM('cash', 'card', 'pix') NOT NULL,
    customer_name VARCHAR(255),
    comanda_id VARCHAR(50) COMMENT 'ID da comanda se for fechamento de conta',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_date (date),
    INDEX idx_payment (payment_method),
    INDEX idx_customer (customer_name)
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
    status ENUM('ordered', 'received') NOT NULL DEFAULT 'received',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE RESTRICT,
    INDEX idx_supplier (supplier_id),
    INDEX idx_date (date),
    INDEX idx_status (status)
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
    is_purchased BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    INDEX idx_product (product_id),
    INDEX idx_purchased (is_purchased)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================
-- TABELA: comandas (Comandas/Contas Abertas)
-- =========================================
CREATE TABLE IF NOT EXISTS comandas (
    id VARCHAR(50) PRIMARY KEY,
    customer_name VARCHAR(255) NOT NULL,
    opened_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP NULL,
    total DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    status ENUM('open', 'closed') NOT NULL DEFAULT 'open',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_status (status),
    INDEX idx_customer (customer_name),
    INDEX idx_opened_at (opened_at)
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
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (comanda_id) REFERENCES comandas(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    INDEX idx_comanda (comanda_id),
    INDEX idx_product (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================
-- TABELA: stock_movements (Histórico de Movimentações)
-- =========================================
CREATE TABLE IF NOT EXISTS stock_movements (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id VARCHAR(50) NOT NULL,
    movement_type ENUM('entrada', 'saida', 'ajuste') NOT NULL,
    quantity DECIMAL(10, 3) NOT NULL,
    previous_stock DECIMAL(10, 3) NOT NULL,
    new_stock DECIMAL(10, 3) NOT NULL,
    reference_type ENUM('sale', 'purchase', 'adjustment', 'recipe') COMMENT 'Tipo de referência',
    reference_id VARCHAR(50) COMMENT 'ID da venda/compra/etc',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    INDEX idx_product (product_id),
    INDEX idx_type (movement_type),
    INDEX idx_date (created_at),
    INDEX idx_reference (reference_type, reference_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================
-- TRIGGERS: Atualizar estoque automaticamente
-- =========================================

-- Trigger: Baixar estoque ao adicionar venda
DELIMITER $$
CREATE TRIGGER after_sale_item_insert 
AFTER INSERT ON sale_items
FOR EACH ROW
BEGIN
    DECLARE v_type VARCHAR(10);
    DECLARE v_stock DECIMAL(10,3);
    
    -- Buscar tipo do produto
    SELECT type, stock INTO v_type, v_stock FROM products WHERE id = NEW.product_id;
    
    IF v_type = 'prato' THEN
        -- Se for prato, baixar os ingredientes da receita
        UPDATE products p
        INNER JOIN product_recipes pr ON p.id = pr.ingredient_id
        SET p.stock = p.stock - (pr.quantity * NEW.quantity)
        WHERE pr.product_id = NEW.product_id;
        
        -- Registrar movimentação dos ingredientes
        INSERT INTO stock_movements (product_id, movement_type, quantity, previous_stock, new_stock, reference_type, reference_id, notes)
        SELECT 
            pr.ingredient_id,
            'saida',
            pr.quantity * NEW.quantity,
            p.stock + (pr.quantity * NEW.quantity),
            p.stock,
            'sale',
            NEW.sale_id,
            CONCAT('Venda de ', NEW.product_name)
        FROM product_recipes pr
        INNER JOIN products p ON p.id = pr.ingredient_id
        WHERE pr.product_id = NEW.product_id;
        
    ELSEIF v_type = 'insumo' THEN
        -- Se for insumo vendido direto (raro)
        UPDATE products SET stock = stock - NEW.quantity WHERE id = NEW.product_id;
        
        INSERT INTO stock_movements (product_id, movement_type, quantity, previous_stock, new_stock, reference_type, reference_id)
        VALUES (NEW.product_id, 'saida', NEW.quantity, v_stock, v_stock - NEW.quantity, 'sale', NEW.sale_id);
    END IF;
END$$
DELIMITER ;

-- Trigger: Adicionar estoque ao receber compra
DELIMITER $$
CREATE TRIGGER after_purchase_item_insert 
AFTER INSERT ON purchase_items
FOR EACH ROW
BEGIN
    DECLARE v_stock DECIMAL(10,3);
    
    SELECT stock INTO v_stock FROM products WHERE id = NEW.product_id;
    
    UPDATE products 
    SET stock = stock + NEW.quantity 
    WHERE id = NEW.product_id;
    
    INSERT INTO stock_movements (product_id, movement_type, quantity, previous_stock, new_stock, reference_type, reference_id)
    VALUES (NEW.product_id, 'entrada', NEW.quantity, v_stock, v_stock + NEW.quantity, 'purchase', NEW.purchase_id);
END$$
DELIMITER ;

-- =========================================
-- VIEWS: Consultas úteis
-- =========================================

-- View: Produtos com estoque baixo
CREATE OR REPLACE VIEW v_low_stock_products AS
SELECT 
    p.id,
    p.name,
    p.stock,
    p.min_stock,
    p.unit,
    p.category,
    s.name AS supplier_name,
    s.contact AS supplier_contact,
    (p.min_stock * 2 - p.stock) AS suggested_order_qty
FROM products p
LEFT JOIN suppliers s ON p.supplier_id = s.id
WHERE p.type = 'insumo' 
  AND p.stock <= p.min_stock 
  AND p.is_active = TRUE
ORDER BY (p.stock / NULLIF(p.min_stock, 0)) ASC;

-- View: Capacidade de produção de pratos
CREATE OR REPLACE VIEW v_dish_production_capacity AS
SELECT 
    p.id,
    p.name,
    p.price,
    p.category,
    MIN(FLOOR(ing.stock / pr.quantity)) AS max_producible
FROM products p
INNER JOIN product_recipes pr ON p.id = pr.product_id
INNER JOIN products ing ON pr.ingredient_id = ing.id
WHERE p.type = 'prato' AND p.is_active = TRUE
GROUP BY p.id, p.name, p.price, p.category
ORDER BY max_producible ASC;

-- View: Vendas do dia
CREATE OR REPLACE VIEW v_today_sales AS
SELECT 
    s.id,
    s.date,
    s.total,
    s.payment_method,
    s.customer_name,
    COUNT(si.id) AS items_count
FROM sales s
LEFT JOIN sale_items si ON s.id = si.sale_id
WHERE DATE(s.date) = CURDATE()
GROUP BY s.id, s.date, s.total, s.payment_method, s.customer_name
ORDER BY s.date DESC;

-- View: Resumo de vendas por período
CREATE OR REPLACE VIEW v_sales_summary AS
SELECT 
    DATE(s.date) AS sale_date,
    COUNT(DISTINCT s.id) AS total_sales,
    SUM(s.total) AS total_revenue,
    AVG(s.total) AS average_ticket,
    SUM(CASE WHEN s.payment_method = 'cash' THEN s.total ELSE 0 END) AS cash_total,
    SUM(CASE WHEN s.payment_method = 'card' THEN s.total ELSE 0 END) AS card_total,
    SUM(CASE WHEN s.payment_method = 'pix' THEN s.total ELSE 0 END) AS pix_total
FROM sales s
GROUP BY DATE(s.date)
ORDER BY sale_date DESC;

-- View: Produtos mais vendidos
CREATE OR REPLACE VIEW v_best_selling_products AS
SELECT 
    p.id,
    p.name,
    p.type,
    p.category,
    SUM(si.quantity) AS total_sold,
    COUNT(DISTINCT si.sale_id) AS sales_count,
    SUM(si.subtotal) AS total_revenue
FROM sale_items si
INNER JOIN products p ON si.product_id = p.id
GROUP BY p.id, p.name, p.type, p.category
ORDER BY total_sold DESC;

-- =========================================
-- STORED PROCEDURES
-- =========================================

-- Procedure: Calcular custo real de um prato
DELIMITER $$
CREATE PROCEDURE sp_calculate_dish_cost(IN p_dish_id VARCHAR(50))
BEGIN
    SELECT 
        p.id,
        p.name AS dish_name,
        SUM(ing.cost * pr.quantity) AS total_cost,
        p.price AS selling_price,
        p.price - SUM(ing.cost * pr.quantity) AS profit_margin,
        ((p.price - SUM(ing.cost * pr.quantity)) / p.price * 100) AS profit_percentage
    FROM products p
    INNER JOIN product_recipes pr ON p.id = pr.product_id
    INNER JOIN products ing ON pr.ingredient_id = ing.id
    WHERE p.id = p_dish_id AND p.type = 'prato'
    GROUP BY p.id, p.name, p.price;
END$$
DELIMITER ;

-- Procedure: Listar ingredientes de um prato
DELIMITER $$
CREATE PROCEDURE sp_get_dish_recipe(IN p_dish_id VARCHAR(50))
BEGIN
    SELECT 
        pr.ingredient_id,
        ing.name AS ingredient_name,
        pr.quantity,
        ing.unit,
        ing.stock AS available_stock,
        ing.cost AS unit_cost,
        (pr.quantity * ing.cost) AS ingredient_cost
    FROM product_recipes pr
    INNER JOIN products ing ON pr.ingredient_id = ing.id
    WHERE pr.product_id = p_dish_id
    ORDER BY ing.name;
END$$
DELIMITER ;

-- =========================================
-- DADOS INICIAIS (SEED DATA)
-- =========================================

-- Fornecedores
INSERT INTO suppliers (id, name, contact, email) VALUES
('sup_001', 'Distribuidora Alimentos Ltda', '(11) 98765-4321', 'contato@distribuidoraalimentos.com.br'),
('sup_002', 'Açougue Bom Preço', '(11) 99876-5432', 'vendas@acouguebompreco.com.br'),
('sup_003', 'Hortifruti Verde Vida', '(11) 97654-3210', 'pedidos@verdevida.com.br'),
('sup_004', 'Bebidas Express', '(11) 96543-2109', 'comercial@bebidasexpress.com.br');

-- Insumos (Ingredientes)
INSERT INTO products (id, name, type, price, cost, stock, min_stock, unit, supplier_id, category) VALUES
-- Carnes
('ing_001', 'Carne Moída Bovina', 'insumo', 0, 25.00, 5.5, 2.0, 'kg', 'sup_002', 'Carnes'),
('ing_002', 'Peito de Frango', 'insumo', 0, 18.00, 8.0, 3.0, 'kg', 'sup_002', 'Carnes'),
('ing_003', 'Bacon em Tiras', 'insumo', 0, 32.00, 2.5, 1.0, 'kg', 'sup_002', 'Carnes'),
('ing_004', 'Linguiça Calabresa', 'insumo', 0, 22.00, 4.0, 2.0, 'kg', 'sup_002', 'Carnes'),

-- Pães e Massas
('ing_005', 'Pão de Hambúrguer', 'insumo', 0, 0.80, 150, 50, 'un', 'sup_001', 'Pães'),
('ing_006', 'Pão Francês', 'insumo', 0, 0.50, 200, 100, 'un', 'sup_001', 'Pães'),
('ing_007', 'Pão de Hot Dog', 'insumo', 0, 0.70, 120, 40, 'un', 'sup_001', 'Pães'),

-- Laticínios
('ing_008', 'Queijo Mussarela Fatiado', 'insumo', 0, 35.00, 3.0, 1.5, 'kg', 'sup_001', 'Laticínios'),
('ing_009', 'Queijo Cheddar', 'insumo', 0, 42.00, 2.0, 1.0, 'kg', 'sup_001', 'Laticínios'),
('ing_010', 'Requeijão Cremoso', 'insumo', 0, 18.00, 4, 2, 'un', 'sup_001', 'Laticínios'),

-- Vegetais
('ing_011', 'Alface Americana', 'insumo', 0, 3.50, 20, 10, 'un', 'sup_003', 'Vegetais'),
('ing_012', 'Tomate', 'insumo', 0, 4.50, 15, 8, 'kg', 'sup_003', 'Vegetais'),
('ing_013', 'Cebola', 'insumo', 0, 3.00, 12, 5, 'kg', 'sup_003', 'Vegetais'),
('ing_014', 'Batata Palito Congelada', 'insumo', 0, 12.00, 25, 10, 'kg', 'sup_001', 'Vegetais'),

-- Condimentos
('ing_015', 'Maionese', 'insumo', 0, 8.50, 10, 5, 'un', 'sup_001', 'Condimentos'),
('ing_016', 'Ketchup', 'insumo', 0, 7.00, 12, 5, 'un', 'sup_001', 'Condimentos'),
('ing_017', 'Mostarda', 'insumo', 0, 6.50, 10, 4, 'un', 'sup_001', 'Condimentos'),
('ing_018', 'Molho Barbecue', 'insumo', 0, 9.00, 8, 3, 'un', 'sup_001', 'Condimentos'),

-- Bebidas
('ing_019', 'Refrigerante Lata 350ml', 'insumo', 0, 2.50, 100, 50, 'un', 'sup_004', 'Bebidas'),
('ing_020', 'Suco Natural Laranja (500ml)', 'insumo', 0, 3.00, 30, 15, 'un', 'sup_004', 'Bebidas'),
('ing_021', 'Água Mineral 500ml', 'insumo', 0, 1.20, 80, 40, 'un', 'sup_004', 'Bebidas'),

-- Outros
('ing_022', 'Óleo de Soja', 'insumo', 0, 8.00, 15, 5, 'l', 'sup_001', 'Diversos'),
('ing_023', 'Sal Refinado', 'insumo', 0, 2.00, 20, 8, 'kg', 'sup_001', 'Diversos');

-- Pratos (Produtos Vendidos)
INSERT INTO products (id, name, type, price, cost, stock, min_stock, unit, category) VALUES
-- Hambúrguers
('dish_001', 'X-Burger Clássico', 'prato', 18.00, 0, 0, 0, 'un', 'Hambúrguers'),
('dish_002', 'X-Bacon Especial', 'prato', 22.00, 0, 0, 0, 'un', 'Hambúrguers'),
('dish_003', 'X-Tudo Completo', 'prato', 28.00, 0, 0, 0, 'un', 'Hambúrguers'),
('dish_004', 'X-Frango Grill', 'prato', 20.00, 0, 0, 0, 'un', 'Hambúrguers'),

-- Lanches
('dish_005', 'Hot Dog Tradicional', 'prato', 12.00, 0, 0, 0, 'un', 'Lanches'),
('dish_006', 'Misto Quente', 'prato', 10.00, 0, 0, 0, 'un', 'Lanches'),

-- Porções
('dish_007', 'Batata Frita Grande', 'prato', 15.00, 0, 0, 0, 'un', 'Porções'),

-- Bebidas
('dish_008', 'Refrigerante Lata', 'prato', 5.00, 0, 0, 0, 'un', 'Bebidas'),
('dish_009', 'Suco Natural Laranja', 'prato', 8.00, 0, 0, 0, 'un', 'Bebidas'),
('dish_010', 'Água Mineral', 'prato', 3.00, 0, 0, 0, 'un', 'Bebidas');

-- Receitas (Fichas Técnicas)
-- X-Burger Clássico
INSERT INTO product_recipes (product_id, ingredient_id, quantity) VALUES
('dish_001', 'ing_005', 1),    -- Pão hambúrguer
('dish_001', 'ing_001', 0.15),  -- Carne moída (150g)
('dish_001', 'ing_008', 0.03),  -- Queijo mussarela (30g)
('dish_001', 'ing_011', 0.05),  -- Alface
('dish_001', 'ing_012', 0.03),  -- Tomate (30g)
('dish_001', 'ing_015', 0.02),  -- Maionese (porção)
('dish_001', 'ing_016', 0.02);  -- Ketchup (porção)

-- X-Bacon Especial
INSERT INTO product_recipes (product_id, ingredient_id, quantity) VALUES
('dish_002', 'ing_005', 1),
('dish_002', 'ing_001', 0.15),
('dish_002', 'ing_008', 0.03),
('dish_002', 'ing_003', 0.05),  -- Bacon
('dish_002', 'ing_011', 0.05),
('dish_002', 'ing_012', 0.03),
('dish_002', 'ing_015', 0.02);

-- X-Tudo Completo
INSERT INTO product_recipes (product_id, ingredient_id, quantity) VALUES
('dish_003', 'ing_005', 1),
('dish_003', 'ing_001', 0.15),
('dish_003', 'ing_008', 0.03),
('dish_003', 'ing_003', 0.05),
('dish_003', 'ing_009', 0.02),  -- Cheddar
('dish_003', 'ing_004', 0.05),  -- Calabresa
('dish_003', 'ing_011', 0.05),
('dish_003', 'ing_012', 0.03),
('dish_003', 'ing_013', 0.02),  -- Cebola
('dish_003', 'ing_015', 0.02),
('dish_003', 'ing_016', 0.02);

-- X-Frango Grill
INSERT INTO product_recipes (product_id, ingredient_id, quantity) VALUES
('dish_004', 'ing_005', 1),
('dish_004', 'ing_002', 0.15),  -- Frango
('dish_004', 'ing_008', 0.03),
('dish_004', 'ing_011', 0.05),
('dish_004', 'ing_012', 0.03),
('dish_004', 'ing_015', 0.02);

-- Hot Dog Tradicional
INSERT INTO product_recipes (product_id, ingredient_id, quantity) VALUES
('dish_005', 'ing_007', 1),     -- Pão hot dog
('dish_005', 'ing_004', 0.10),  -- Salsicha/Calabresa
('dish_005', 'ing_015', 0.02),
('dish_005', 'ing_016', 0.02),
('dish_005', 'ing_017', 0.01),  -- Mostarda
('dish_005', 'ing_010', 0.02);  -- Requeijão

-- Misto Quente
INSERT INTO product_recipes (product_id, ingredient_id, quantity) VALUES
('dish_006', 'ing_006', 1),     -- Pão francês
('dish_006', 'ing_008', 0.03);  -- Queijo

-- Batata Frita Grande
INSERT INTO product_recipes (product_id, ingredient_id, quantity) VALUES
('dish_007', 'ing_014', 0.40),  -- Batata 400g
('dish_007', 'ing_022', 0.10);  -- Óleo

-- Bebidas (vendidas direto do estoque)
INSERT INTO product_recipes (product_id, ingredient_id, quantity) VALUES
('dish_008', 'ing_019', 1),
('dish_009', 'ing_020', 1),
('dish_010', 'ing_021', 1);

-- =========================================
-- ÍNDICES ADICIONAIS PARA PERFORMANCE
-- =========================================

-- Índice composto para consultas frequentes
CREATE INDEX idx_products_type_active ON products(type, is_active);
CREATE INDEX idx_sales_date_payment ON sales(date, payment_method);
CREATE INDEX idx_movements_product_date ON stock_movements(product_id, created_at);

-- =========================================
-- INFORMAÇÕES DO BANCO
-- =========================================

SELECT 'Database created successfully!' AS status;
SELECT COUNT(*) AS total_suppliers FROM suppliers;
SELECT COUNT(*) AS total_products FROM products;
SELECT COUNT(*) AS total_ingredients FROM products WHERE type = 'insumo';
SELECT COUNT(*) AS total_dishes FROM products WHERE type = 'prato';
SELECT COUNT(*) AS total_recipes FROM product_recipes;

-- =========================================
-- FIM DO SCRIPT
-- =========================================
