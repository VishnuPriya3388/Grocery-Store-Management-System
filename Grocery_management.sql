CREATE DATABASE IF NOT EXISTS grocery_store_db;
USE grocery_store_db;
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS inventory_logs;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS suppliers;
DROP TABLE IF EXISTS categories;
DROP VIEW IF EXISTS vw_low_stock_alerts;
DROP VIEW IF EXISTS vw_product_profitability;
DROP VIEW IF EXISTS vw_customer_leaderboard;
DROP VIEW IF EXISTS vw_daily_sales_summary;
SET FOREIGN_KEY_CHECKS = 1;

-- CREATE TABLES
-- Table: categories
CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
-- Table: suppliers
CREATE TABLE suppliers (
    supplier_id INT AUTO_INCREMENT PRIMARY KEY,
    company_name VARCHAR(100) NOT NULL,
    contact_name VARCHAR(100),
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    address TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
-- Table: products
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    barcode VARCHAR(50) UNIQUE,
    product_name VARCHAR(100) NOT NULL,
    category_id INT NOT NULL,
    supplier_id INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
    cost_price DECIMAL(10,2) NOT NULL CHECK (cost_price >= 0),
    stock_quantity INT NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    reorder_level INT NOT NULL DEFAULT 10 CHECK (reorder_level >= 0),
    unit_of_measure VARCHAR(20) DEFAULT 'pcs',
    status ENUM('ACTIVE', 'DISCONTINUED', 'OUT_OF_STOCK') DEFAULT 'ACTIVE',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_products_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;
-- Table: customers
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20) UNIQUE,
    email VARCHAR(100) UNIQUE,
    loyalty_points INT DEFAULT 0 CHECK (loyalty_points >= 0),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
-- Table: employees
CREATE TABLE employees (
    employee_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    role ENUM('MANAGER', 'CASHIER', 'INVENTORY_CLERK') NOT NULL DEFAULT 'CASHIER',
    phone VARCHAR(20),
    email VARCHAR(100) UNIQUE,
    salary DECIMAL(10,2) NOT NULL CHECK (salary > 0),
    hire_date DATE NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
-- Table: orders
CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NULL,
    employee_id INT NOT NULL,
    order_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    subtotal DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (subtotal >= 0),
    tax_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (tax_amount >= 0),
    discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (discount_amount >= 0),
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (total_amount >= 0),
    payment_method ENUM('CASH', 'CREDIT_CARD', 'DEBIT_CARD', 'MOBILE_PAYMENT') DEFAULT 'CASH',
    payment_status ENUM('COMPLETED', 'PENDING', 'REFUNDED', 'CANCELLED') DEFAULT 'COMPLETED',
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_orders_employee FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;
-- Table: order_items
CREATE TABLE order_items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
    subtotal DECIMAL(10,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_order_items_product FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;
-- Table: inventory_logs
CREATE TABLE inventory_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    change_type ENUM('RESTOCK', 'SALE', 'RETURN', 'DAMAGE_EXPIRED', 'ADJUSTMENT') NOT NULL,
    quantity_changed INT NOT NULL,
    stock_after INT NOT NULL,
    log_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    notes VARCHAR(255),
    CONSTRAINT fk_inventory_logs_product FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
-- Performance Indexes
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_barcode ON products(barcode);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_orders_customer ON orders(customer_id);

-- 3. INSERT SAMPLE DATA

INSERT INTO categories (category_id, category_name, description) VALUES
(1, 'Produce', 'Fresh fruits, vegetables, and leafy greens'),
(2, 'Dairy & Eggs', 'Milk, cheese, butter, yogurt, and eggs'),
(3, 'Bakery', 'Freshly baked breads, pastries, and cakes'),
(4, 'Meat & Seafood', 'Fresh poultry, beef, pork, and seafood'),
(5, 'Beverages', 'Juices, soft drinks, water, tea, and coffee'),
(6, 'Snacks & Sweets', 'Chips, crackers, chocolates, and cookies');
INSERT INTO suppliers (supplier_id, company_name, contact_name, phone, email, address) VALUES
(1, 'Fresh Harvest Farms', 'John Miller', '555-0101', 'orders@freshharvest.com', '100 Green Valley Rd, CA'),
(2, 'Alpine Valley Dairy', 'Sarah Jenkins', '555-0102', 'supply@alpinedairy.com', '45 Dairy Farm Way, VT'),
(3, 'Golden Grain Bakery Co.', 'Robert Crust', '555-0103', 'sales@goldengrain.com', '12 Wheat Street, IL'),
(4, 'Prime Meats & Seafood', 'David Carnes', '555-0104', 'contact@primemeats.com', '88 Slaughterhouse Ave, TX'),
(5, 'Refreshing Beverage Distributors', 'Elena Gomez', '555-0105', 'info@refreshbev.com', '300 Ocean Drive, FL');
INSERT INTO products (product_id, barcode, product_name, category_id, supplier_id, unit_price, cost_price, stock_quantity, reorder_level, unit_of_measure, status) VALUES
(1, '8901001001', 'Organic Red Apples', 1, 1, 2.99, 1.50, 150, 30, 'kg', 'ACTIVE'),
(2, '8901001002', 'Fresh Bananas', 1, 1, 1.49, 0.70, 200, 40, 'kg', 'ACTIVE'),
(3, '8901001003', 'Avocado (Large)', 1, 1, 1.99, 1.00, 12, 15, 'pcs', 'ACTIVE'),
(4, '8901002001', 'Whole Milk 1L', 2, 2, 3.49, 2.10, 80, 20, 'bottle', 'ACTIVE'),
(5, '8901002002', 'Cheddar Cheese 250g', 2, 2, 4.29, 2.50, 45, 10, 'pack', 'ACTIVE'),
(6, '8901002003', 'Greek Yogurt Plain 500g', 2, 2, 3.99, 2.20, 8, 15, 'tub', 'ACTIVE'),
(7, '8901003001', 'Whole Wheat Bread', 3, 3, 2.89, 1.30, 35, 10, 'loaf', 'ACTIVE'),
(8, '8901004001', 'Boneless Chicken Breast', 4, 4, 8.99, 5.50, 60, 15, 'kg', 'ACTIVE'),
(9, '8901005001', 'Pure Orange Juice 1L', 5, 5, 3.79, 2.00, 90, 20, 'carton', 'ACTIVE'),
(10, '8901006001', 'Classic Potato Chips 150g', 6, 5, 2.49, 1.10, 100, 20, 'bag', 'ACTIVE');
INSERT INTO customers (customer_id, first_name, last_name, phone, email, loyalty_points) VALUES
(1, 'Alice', 'Smith', '555-1111', 'alice.smith@email.com', 120),
(2, 'Bob', 'Jones', '555-2222', 'bob.jones@email.com', 45),
(3, 'Charlie', 'Brown', '555-3333', 'charlie.b@email.com', 210);
INSERT INTO employees (employee_id, first_name, last_name, role, phone, email, salary, hire_date) VALUES
(1, 'Sarah', 'Connor', 'MANAGER', '555-9001', 's.connor@store.com', 55000.00, '2022-01-15'),
(2, 'Michael', 'Scott', 'CASHIER', '555-9002', 'm.scott@store.com', 32000.00, '2023-03-01');
INSERT INTO orders (order_id, customer_id, employee_id, order_date, subtotal, tax_amount, discount_amount, total_amount, payment_method, payment_status) VALUES
(1, 1, 2, '2026-09-20 10:15:00', 17.75, 1.42, 1.00, 18.17, 'CREDIT_CARD', 'COMPLETED'),
(2, 2, 2, '2026-09-21 11:30:00', 12.97, 1.04, 0.00, 14.01, 'CASH', 'COMPLETED');
INSERT INTO order_items (order_item_id, order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 2, 2.99),
(2, 1, 4, 2, 3.49),
(3, 1, 7, 1, 2.89),
(4, 2, 2, 2, 1.49),
(5, 2, 5, 1, 4.29);

-- 4. VIEWS

-- Low Stock Warning View
CREATE VIEW vw_low_stock_alerts AS
SELECT 
    p.product_id,
    p.product_name,
    c.category_name,
    s.company_name AS supplier_name,
    s.phone AS supplier_phone,
    p.stock_quantity,
    p.reorder_level,
    (p.reorder_level - p.stock_quantity) AS shortage_qty
FROM products p
JOIN categories c ON p.category_id = c.category_id
JOIN suppliers s ON p.supplier_id = s.supplier_id
WHERE p.stock_quantity <= p.reorder_level;
-- Profitability View
CREATE VIEW vw_product_profitability AS
SELECT 
    p.product_id,
    p.product_name,
    c.category_name,
    p.cost_price,
    p.unit_price,
    (p.unit_price - p.cost_price) AS profit_per_unit,
    COALESCE(SUM(oi.quantity), 0) AS total_units_sold,
    COALESCE(SUM(oi.subtotal), 0) AS total_revenue
FROM products p
JOIN categories c ON p.category_id = c.category_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, c.category_name, p.cost_price, p.unit_price;

-- 5. PROCEDURES & TRIGGERS

DELIMITER //
-- Function: Stock level status
CREATE FUNCTION fn_get_stock_status(p_product_id INT) 
RETURNS VARCHAR(20)
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_stock INT;
    DECLARE v_reorder INT;
    SELECT stock_quantity, reorder_level INTO v_stock, v_reorder FROM products WHERE product_id = p_product_id;
    IF v_stock IS NULL THEN RETURN 'NOT FOUND';
    ELSEIF v_stock = 0 THEN RETURN 'OUT OF STOCK';
    ELSEIF v_stock <= v_reorder THEN RETURN 'REORDER NEEDED';
    ELSE RETURN 'SUFFICIENT';
    END IF;
END //
-- Trigger: Auto deduct stock on sale
CREATE TRIGGER trg_after_order_item_insert
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
    UPDATE products SET stock_quantity = stock_quantity - NEW.quantity WHERE product_id = NEW.product_id;
END //
-- Stored Procedure: Restock product
DROP PROCEDURE IF EXISTS sp_restock_product;
CREATE PROCEDURE sp_restock_product(
    IN p_product_id INT,
    IN p_quantity INT,
    IN p_notes VARCHAR(255)
)
BEGIN
    UPDATE products SET stock_quantity = stock_quantity + p_quantity WHERE product_id = p_product_id;
    INSERT INTO inventory_logs (product_id, change_type, quantity_changed, stock_after, notes)
    SELECT p_product_id, 'RESTOCK', p_quantity, stock_quantity, COALESCE(p_notes, 'Restocked') FROM products WHERE product_id = p_product_id;
END //
DELIMITER ;


-- Query 1: Display all Low-Stock Products requiring reorder
SELECT * FROM vw_low_stock_alerts;
-- Query 2: Top Selling Products by Sales Revenue
SELECT 
    p.product_name,
    c.category_name,
    SUM(oi.quantity) AS total_units_sold,
    SUM(oi.subtotal) AS gross_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
GROUP BY p.product_id, p.product_name, c.category_name
ORDER BY gross_revenue DESC;
-- Query 3: Total Stock Valuation per Category
SELECT 
    c.category_name,
    COUNT(p.product_id) AS total_items,
    SUM(p.stock_quantity) AS stock_count,
    SUM(p.stock_quantity * p.cost_price) AS total_cost_value,
    SUM(p.stock_quantity * p.unit_price) AS total_retail_value
FROM categories c
JOIN products p ON c.category_id = p.category_id
GROUP BY c.category_id, c.category_name;
-- Query 4: Execute Stored Procedure to Restock product ID 3 (Avocado) by 50 units
CALL sp_restock_product(3, 50, 'New delivery received');