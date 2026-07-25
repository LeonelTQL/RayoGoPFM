require('dotenv').config();
const bcrypt = require('bcryptjs');
const { Pool } = require('pg');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });


async function upsertSetting(key, value, description) {
  await pool.query(
    `INSERT INTO app_settings (key, value, description)
     VALUES ($1, $2, $3)
     ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, description = EXCLUDED.description, updated_at = CURRENT_TIMESTAMP`,
    [key, value, description]
  );
}

async function upsertUser({ name, email, phone, role }) {
  const passwordHash = await bcrypt.hash('12345678', 10);
  const result = await pool.query(
    `INSERT INTO users (name, email, password_hash, phone, role)
     VALUES ($1, $2, $3, $4, $5)
     ON CONFLICT (email) DO UPDATE
     SET name = EXCLUDED.name, phone = EXCLUDED.phone, role = EXCLUDED.role, password_hash = EXCLUDED.password_hash, active = TRUE
     RETURNING id`,
    [name, email, passwordHash, phone, role]
  );
  return result.rows[0].id;
}

async function upsertCategory(name) {
  const result = await pool.query(
    `INSERT INTO categories (name) VALUES ($1)
     ON CONFLICT (name) DO UPDATE SET active = TRUE
     RETURNING id`,
    [name]
  );
  return result.rows[0].id;
}

async function upsertRestaurant(data) {
  const result = await pool.query(
    `INSERT INTO restaurants (name, description, logo_url, cover_url, rating, rating_count, delivery_minutes_min, delivery_minutes_max, delivery_fee, commission_rate, min_order_amount)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,5.00)
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
       active = TRUE
     RETURNING id`,
    [data.name, data.description, data.logoUrl, data.coverUrl, data.rating, data.ratingCount, data.min, data.max, data.deliveryFee, data.commissionRate]
  );
  return result.rows[0].id;
}

async function seed() {
  await upsertSetting('service_fee', '0.35', 'Cargo de servicio de plataforma aplicado por pedido');
  await upsertSetting('priority_delivery_fee', '0.90', 'Cargo opcional por envío prioritario');

  const adminId = await upsertUser({ name: 'Administrador Smart Delivery', email: 'admin@smartdelivery.com', phone: '0999999999', role: 'admin' });
  const clientId = await upsertUser({ name: 'Cliente Demo', email: 'cliente@smartdelivery.com', phone: '0988888888', role: 'cliente' });
  await upsertUser({ name: 'Repartidor Demo', email: 'repartidor@smartdelivery.com', phone: '0977777777', role: 'repartidor' });

  const categories = {};
  for (const name of ['Sushi', 'Hamburguesas', 'Almuerzos', 'Bebidas', 'Postres', 'Súper']) {
    categories[name] = await upsertCategory(name);
  }

  const restaurants = {
    sushi: await upsertRestaurant({
      name: 'Local Sushi Demo',
      description: 'Rolls, combos y promociones japonesas.',
      logoUrl: null,
      coverUrl: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=1000',
      rating: 4.6,
      ratingCount: 411,
      min: 35,
      max: 55,
      deliveryFee: 1.79,
      commissionRate: 0.22
    }),
    burger: await upsertRestaurant({
      name: 'Local Hamburguesas Demo',
      description: 'Hamburguesas artesanales y papas.',
      logoUrl: null,
      coverUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=1000',
      rating: 4.7,
      ratingCount: 235,
      min: 20,
      max: 35,
      deliveryFee: 1.49,
      commissionRate: 0.18
    }),
    menestra: await upsertRestaurant({
      name: 'Local Almuerzos Demo',
      description: 'Menestras, chuletas y almuerzos.',
      logoUrl: null,
      coverUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=1000',
      rating: 4.4,
      ratingCount: 198,
      min: 25,
      max: 40,
      deliveryFee: 1.35,
      commissionRate: 0.16
    }),
    market: await upsertRestaurant({
      name: 'Local Market Demo',
      description: 'Productos de mercado y bebidas sin restricciones.',
      logoUrl: null,
      coverUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=1000',
      rating: 4.5,
      ratingCount: 98,
      min: 30,
      max: 50,
      deliveryFee: 1.25,
      commissionRate: 0.12
    })
  };

  const products = [
    { restaurant: 'sushi', category: 'Sushi', name: 'Combo sushi promocional', description: '10 bocados california + bebida 300 ml. Soya y jengibre incluidos.', price: 4.99, originalPrice: 10.99, discount: 55, stock: 35, image: 'https://images.unsplash.com/photo-1617196034796-73dfa7b1fd56?w=900' },
    { restaurant: 'sushi', category: 'Sushi', name: 'Combinación sushi 14 bocados', description: 'Rolls mixtos con salmón, aguacate y queso crema.', price: 14.99, originalPrice: null, discount: 0, stock: 25, image: 'https://images.unsplash.com/photo-1553621042-f6e147245754?w=900' },
    { restaurant: 'sushi', category: 'Sushi', name: 'Combo familiar de sushi', description: 'Variedad de rolls para compartir.', price: 19.99, originalPrice: 24.50, discount: 18, stock: 18, image: 'https://images.unsplash.com/photo-1611143669185-af224c5e3252?w=900' },
    { restaurant: 'burger', category: 'Hamburguesas', name: 'Hamburguesa clásica', description: 'Carne, queso, lechuga, tomate y salsa de la casa.', price: 5.75, originalPrice: null, discount: 0, stock: 30, image: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=900' },
    { restaurant: 'burger', category: 'Hamburguesas', name: 'Combo hamburguesa + papas', description: 'Hamburguesa artesanal con papas y bebida.', price: 6.99, originalPrice: 8.99, discount: 22, stock: 28, image: 'https://images.unsplash.com/photo-1550547660-d9450f859349?w=900' },
    { restaurant: 'menestra', category: 'Almuerzos', name: 'Menestra completa + bebida', description: 'Menestra, arroz, patacones, carne y bebida.', price: 5.25, originalPrice: 9.99, discount: 47, stock: 40, image: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=900' },
    { restaurant: 'menestra', category: 'Almuerzos', name: 'Almuerzo del día', description: 'Sopa, plato fuerte y bebida natural.', price: 5.00, originalPrice: null, discount: 0, stock: 45, image: 'https://images.unsplash.com/photo-1543353071-873f17a7a088?w=900' },
    { restaurant: 'market', category: 'Bebidas', name: 'Bebida personal 300 ml', description: 'Bebida personal para acompañar tu pedido.', price: 1.25, originalPrice: null, discount: 0, stock: 80, image: 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=900' },
    { restaurant: 'market', category: 'Postres', name: 'Postre personal', description: 'Postre frío porción personal.', price: 2.50, originalPrice: 3.25, discount: 23, stock: 20, image: 'https://images.unsplash.com/photo-1533134242443-d4fd215305ad?w=900' }
  ];

  for (const product of products) {
    await pool.query(
      `INSERT INTO products (restaurant_id, category_id, name, description, price, original_price, discount_percent, stock, image_url)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
       ON CONFLICT DO NOTHING`,
      [restaurants[product.restaurant], categories[product.category], product.name, product.description, product.price, product.originalPrice, product.discount, product.stock, product.image]
    );
  }

  await pool.query(
    `INSERT INTO addresses (user_id, label, address_line, latitude, longitude, is_default)
     VALUES ($1, 'Casa demo', 'Av. Demo 123 y Calle Principal', -0.180653, -78.467834, TRUE)
     ON CONFLICT DO NOTHING`,
    [clientId]
  );

  console.log('Seed completado. Admin:', adminId);
  await pool.end();
}

seed().catch(async (error) => {
  console.error('Error ejecutando seed:', error.message);
  await pool.end();
  process.exit(1);
});
