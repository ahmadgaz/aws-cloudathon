CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price NUMERIC(10, 2) NOT NULL,
    stock INT NOT NULL DEFAULT 0
);

INSERT INTO products (name, description, price, stock) VALUES
('T-shirt', 'A comfortable cotton t-shirt', 19.99, 100),
('Coffee Mug', 'Ceramic mug for hot beverages', 9.99, 50),
('Notebook', 'A5 size ruled notebook', 4.99, 200); 