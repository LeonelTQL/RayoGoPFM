-- Database Initialization Script for Smart Delivery
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Enums
DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('cliente', 'repartidor', 'admin');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE order_status AS ENUM ('pendiente', 'confirmado', 'preparando', 'asignado', 'en_camino', 'entregado', 'cancelado');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE payment_method AS ENUM ('efectivo', 'transferencia', 'comprobante');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE payment_status AS ENUM ('pendiente', 'aprobado', 'rechazado');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Tables
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firebase_uid VARCHAR(150) UNIQUE,
  name VARCHAR(120) NOT NULL,
  email VARCHAR(150) UNIQUE NOT NULL,
  password_hash VARCHAR(255),
  phone VARCHAR(20) NOT NULL,
  role user_role NOT NULL DEFAULT 'cliente',
  avatar_url TEXT,
  fcm_token TEXT,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS addresses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  label VARCHAR(80) NOT NULL,
  address_line TEXT NOT NULL,
  latitude DECIMAL(10,7) NOT NULL,
  longitude DECIMAL(10,7) NOT NULL,
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL UNIQUE,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS app_settings (
  key VARCHAR(80) PRIMARY KEY,
  value TEXT NOT NULL,
  description TEXT,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS restaurants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(140) NOT NULL UNIQUE,
  description TEXT,
  logo_url TEXT,
  cover_url TEXT,
  rating DECIMAL(3,2) NOT NULL DEFAULT 4.60,
  rating_count INT NOT NULL DEFAULT 120,
  delivery_minutes_min INT NOT NULL DEFAULT 25,
  delivery_minutes_max INT NOT NULL DEFAULT 45,
  delivery_fee DECIMAL(10,2) NOT NULL DEFAULT 1.50 CHECK (delivery_fee >= 0),
  commission_rate DECIMAL(5,4) NOT NULL DEFAULT 0.1800 CHECK (commission_rate >= 0 AND commission_rate <= 1),
  min_order_amount DECIMAL(10,2) NOT NULL DEFAULT 5.00 CHECK (min_order_amount >= 0),
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  name VARCHAR(120) NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
  original_price DECIMAL(10,2) CHECK (original_price IS NULL OR original_price >= price),
  discount_percent INT NOT NULL DEFAULT 0 CHECK (discount_percent >= 0 AND discount_percent <= 90),
  stock INT NOT NULL CHECK (stock >= 0),
  image_url TEXT,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES users(id),
  rider_id UUID REFERENCES users(id),
  delivery_address_id UUID REFERENCES addresses(id),
  restaurant_id UUID REFERENCES restaurants(id),
  status order_status NOT NULL DEFAULT 'pendiente',
  subtotal DECIMAL(10,2) NOT NULL CHECK (subtotal >= 0),
  delivery_fee DECIMAL(10,2) NOT NULL DEFAULT 1.50 CHECK (delivery_fee >= 0),
  service_fee DECIMAL(10,2) NOT NULL DEFAULT 0.35 CHECK (service_fee >= 0),
  restaurant_commission DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (restaurant_commission >= 0),
  restaurant_payout DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (restaurant_payout >= 0),
  total DECIMAL(10,2) NOT NULL CHECK (total >= 0),
  payment_method payment_method NOT NULL,
  payment_status payment_status NOT NULL DEFAULT 'pendiente',
  note TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE SET NULL,
  product_name VARCHAR(120) NOT NULL,
  quantity INT NOT NULL CHECK (quantity > 0),
  unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
  total DECIMAL(10,2) NOT NULL CHECK (total >= 0)
);

CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  method payment_method NOT NULL,
  status payment_status NOT NULL DEFAULT 'pendiente',
  amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
  proof_image_url TEXT,
  transaction_reference VARCHAR(120),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS delivery_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  rider_id UUID NOT NULL REFERENCES users(id),
  latitude DECIMAL(10,7) NOT NULL,
  longitude DECIMAL(10,7) NOT NULL,
  accuracy DECIMAL(10,2),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS delivery_proofs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  rider_id UUID NOT NULL REFERENCES users(id),
  image_url TEXT NOT NULL,
  note TEXT,
  delivered_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_products_active ON products(active);
CREATE INDEX IF NOT EXISTS idx_products_restaurant ON products(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_rider ON orders(rider_id);
CREATE INDEX IF NOT EXISTS idx_orders_restaurant ON orders(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_delivery_locations_order ON delivery_locations(order_id, created_at DESC);

-- --- SEED DATA ---

-- App Settings
INSERT INTO app_settings (key, value, description)
VALUES 
  ('service_fee', '0.35', 'Cargo de servicio de plataforma aplicado por pedido'),
  ('priority_delivery_fee', '0.90', 'Cargo opcional por envío prioritario')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, description = EXCLUDED.description;

-- Users (Admin, Cliente, Repartidor) - Password '12345678'
-- bcrypt hash of sha256('12345678') used: $2a$10$L50IrmdkJHNez7THRgUXJOpYpLh7ANASK6o9ckbPssebE/OETMnBC
INSERT INTO users (id, name, email, password_hash, phone, role)
VALUES 
  ('a1111111-1111-1111-1111-111111111111', 'Administrador Smart Delivery', 'admin@smartdelivery.com', '$2a$10$L50IrmdkJHNez7THRgUXJOpYpLh7ANASK6o9ckbPssebE/OETMnBC', '0999999999', 'admin'),
  ('c2222222-2222-2222-2222-222222222222', 'Cliente Demo', 'cliente@smartdelivery.com', '$2a$10$L50IrmdkJHNez7THRgUXJOpYpLh7ANASK6o9ckbPssebE/OETMnBC', '0988888888', 'cliente'),
  ('d3333333-3333-3333-3333-333333333333', 'Repartidor Demo', 'repartidor@smartdelivery.com', '$2a$10$L50IrmdkJHNez7THRgUXJOpYpLh7ANASK6o9ckbPssebE/OETMnBC', '0977777777', 'repartidor')
ON CONFLICT (email) DO UPDATE 
SET name = EXCLUDED.name, password_hash = EXCLUDED.password_hash, phone = EXCLUDED.phone, role = EXCLUDED.role, active = TRUE;

-- Addresses
INSERT INTO addresses (id, user_id, label, address_line, latitude, longitude, is_default)
VALUES ('d4444444-4444-4444-4444-444444444444', 'c2222222-2222-2222-2222-222222222222', 'Casa demo', 'Av. Demo 123 y Calle Principal', -0.180653, -78.467834, TRUE)
ON CONFLICT DO NOTHING;

-- Categories
INSERT INTO categories (id, name)
VALUES 
  ('e5555555-5555-5555-5555-555555555555', 'Sushi'),
  ('e6666666-6666-6666-6666-666666666666', 'Hamburguesas'),
  ('e7777777-7777-7777-7777-777777777777', 'Almuerzos'),
  ('e8888888-8888-8888-8888-888888888888', 'Bebidas'),
  ('e9999999-9999-9999-9999-999999999999', 'Postres'),
  ('f0000000-0000-0000-0000-000000000000', 'Súper')
ON CONFLICT (name) DO UPDATE SET active = TRUE;

-- Restaurants
INSERT INTO restaurants (id, name, description, logo_url, cover_url, rating, rating_count, delivery_minutes_min, delivery_minutes_max, delivery_fee, commission_rate, min_order_amount)
VALUES 
  ('11111111-2222-3333-4444-555555555555', 'Local Sushi Demo', 'Rolls, combos y promociones japonesas.', null, 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=1000', 4.6, 411, 35, 55, 1.79, 0.22, 5.00),
  ('22222222-3333-4444-5555-666666666666', 'Local Hamburguesas Demo', 'Hamburguesas artesanales y papas.', null, 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=1000', 4.7, 235, 20, 35, 1.49, 0.18, 5.00),
  ('33333333-4444-5555-6666-777777777777', 'Local Almuerzos Demo', 'Menestras, chuletas y almuerzos.', null, 'https://images.unsplash.com/photo-1544025162-d76694265947?w=1000', 4.4, 198, 25, 40, 1.35, 0.16, 5.00),
  ('44444444-5555-6666-7777-888888888888', 'Local Market Demo', 'Productos de mercado y bebidas sin restricciones.', null, 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=1000', 4.5, 98, 30, 50, 1.25, 0.12, 5.00)
ON CONFLICT (name) DO UPDATE SET
  description = EXCLUDED.description,
  logo_url = EXCLUDED.logo_url,
  cover_url = EXCLUDED.cover_url,
  rating = EXCLUDED.rating,
  rating_count = EXCLUDED.rating_count,
  delivery_minutes_min = EXCLUDED.delivery_minutes_min,
  delivery_minutes_max = EXCLUDED.delivery_minutes_max,
  delivery_fee = EXCLUDED.delivery_fee,
  commission_rate = EXCLUDED.commission_rate,
  min_order_amount = EXCLUDED.min_order_amount,
  active = TRUE;

-- Products
INSERT INTO products (restaurant_id, category_id, name, description, price, original_price, discount_percent, stock, image_url)
VALUES 
  ('11111111-2222-3333-4444-555555555555', 'e5555555-5555-5555-5555-555555555555', 'Combo sushi promocional', '10 bocados california + bebida 300 ml. Soya y jengibre incluidos.', 4.99, 10.99, 55, 35, 'https://images.unsplash.com/photo-1617196034796-73dfa7b1fd56?w=900'),
  ('11111111-2222-3333-4444-555555555555', 'e5555555-5555-5555-5555-555555555555', 'Combinación sushi 14 bocados', 'Rolls mixtos con salmón, aguacate y queso crema.', 14.99, null, 0, 25, 'https://images.unsplash.com/photo-1553621042-f6e147245754?w=900'),
  ('11111111-2222-3333-4444-555555555555', 'e5555555-5555-5555-5555-555555555555', 'Combo familiar de sushi', 'Variedad de rolls para compartir.', 19.99, 24.50, 18, 18, 'https://images.unsplash.com/photo-1611143669185-af224c5e3252?w=900'),
  ('22222222-3333-4444-5555-666666666666', 'e6666666-6666-6666-6666-666666666666', 'Hamburguesa clásica', 'Carne, queso, lechuga, tomate y salsa de la casa.', 5.75, null, 0, 30, 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=900'),
  ('22222222-3333-4444-5555-666666666666', 'e6666666-6666-6666-6666-666666666666', 'Combo hamburguesa + papas', 'Hamburguesa artesanal con papas y bebida.', 6.99, 8.99, 22, 28, 'https://images.unsplash.com/photo-1550547660-d9450f859349?w=900'),
  ('33333333-4444-5555-6666-777777777777', 'e7777777-7777-7777-7777-777777777777', 'Menestra completa + bebida', 'Menestra, arroz, patacones, carne y bebida.', 5.25, 9.99, 47, 40, 'https://images.unsplash.com/photo-1544025162-d76694265947?w=900'),
  ('33333333-4444-5555-6666-777777777777', 'e7777777-7777-7777-7777-777777777777', 'Almuerzo del día', 'Sopa, plato fuerte y bebida natural.', 5.00, null, 0, 45, 'https://images.unsplash.com/photo-1543353071-873f17a7a088?w=900'),
  ('44444444-5555-6666-7777-888888888888', 'e8888888-8888-8888-8888-888888888888', 'Bebida personal 300 ml', 'Bebida personal para acompañar tu pedido.', 1.25, null, 0, 80, 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=900'),
  ('44444444-5555-6666-7777-888888888888', 'e9999999-9999-9999-9999-999999999999', 'Postre personal', 'Postre frío porción personal.', 2.50, 3.25, 23, 20, 'https://images.unsplash.com/photo-1533134242443-d4fd215305ad?w=900')
ON CONFLICT DO NOTHING;
