-- V3: Limpieza de datos demo y compatibilidad para bases creadas con versiones anteriores.
-- La app no usa direcciones, nombres personales ni locales quemados en Flutter.
-- Si ya ejecutaste una versión anterior, esta migración reemplaza datos demo sensibles por datos genéricos.


CREATE TABLE IF NOT EXISTS app_settings (
  key VARCHAR(80) PRIMARY KEY,
  value TEXT NOT NULL,
  description TEXT,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO app_settings (key, value, description)
VALUES ('service_fee', '0.35', 'Cargo de servicio de plataforma aplicado por pedido')
ON CONFLICT (key) DO NOTHING;

INSERT INTO app_settings (key, value, description)
VALUES ('priority_delivery_fee', '0.90', 'Cargo opcional por envío prioritario')
ON CONFLICT (key) DO NOTHING;

ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS min_order_amount DECIMAL(10,2) NOT NULL DEFAULT 5.00 CHECK (min_order_amount >= 0);
ALTER TABLE products ADD COLUMN IF NOT EXISTS original_price DECIMAL(10,2) CHECK (original_price IS NULL OR original_price >= price);
ALTER TABLE products ADD COLUMN IF NOT EXISTS discount_percent INT NOT NULL DEFAULT 0 CHECK (discount_percent >= 0 AND discount_percent <= 90);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS service_fee DECIMAL(10,2) NOT NULL DEFAULT 0.35 CHECK (service_fee >= 0);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS restaurant_commission DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (restaurant_commission >= 0);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS restaurant_payout DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (restaurant_payout >= 0);

UPDATE users
SET name = 'Cliente Demo'
WHERE email = 'cliente@smartdelivery.com' AND name = 'Leonel Tipan';

UPDATE addresses
SET label = 'Casa demo', address_line = 'Av. Demo 123 y Calle Principal'
WHERE address_line ILIKE '%Imbabura%' OR address_line ILIKE '%Cayambe%';

UPDATE restaurants SET name = 'Local Sushi Demo' WHERE name = 'Kobe Sushi Demo';
UPDATE restaurants SET name = 'Local Hamburguesas Demo' WHERE name = 'Burger House Demo';
UPDATE restaurants SET name = 'Local Almuerzos Demo' WHERE name = 'Menestra Express Demo';
UPDATE restaurants SET name = 'Local Market Demo' WHERE name = 'Smart Market Demo';

UPDATE products SET name = 'Combo sushi promocional' WHERE name = 'Promo California';
UPDATE products SET name = 'Combinación sushi 14 bocados' WHERE name = 'Combinación 14 bocados';
UPDATE products SET name = 'Combo familiar de sushi' WHERE name = 'Combo familiar sushi';
UPDATE products SET name = 'Hamburguesa clásica' WHERE name = 'Burger clásica';
UPDATE products SET name = 'Combo hamburguesa + papas' WHERE name = 'Combo burger + papas';
UPDATE products SET name = 'Menestra completa + bebida' WHERE name = 'Mega menestra + bebida';
UPDATE products SET name = 'Almuerzo del día' WHERE name = 'Almuerzo ejecutivo';
