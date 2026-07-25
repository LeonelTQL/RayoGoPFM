const { Router } = require('express');
const { z } = require('zod');
const db = require('../../config/db');
const { requireAuth } = require('../../middlewares/auth.middleware');
const { allowRoles } = require('../../middlewares/role.middleware');
const { validate } = require('../../middlewares/validate.middleware');

const router = Router();

const productSchema = z.object({
  restaurantId: z.string().uuid().nullable().optional(),
  categoryId: z.string().uuid().nullable().optional(),
  name: z.string().min(2, 'Nombre requerido.'),
  description: z.string().optional().nullable(),
  price: z.number().positive('El precio debe ser mayor a 0.'),
  originalPrice: z.number().positive().nullable().optional(),
  discountPercent: z.number().int().min(0).max(90).optional().default(0),
  stock: z.number().int().min(0, 'El stock no puede ser negativo.'),
  imageUrl: z.string().url().nullable().optional()
});

function mapProduct(row) {
  return {
    id: row.id,
    categoryId: row.category_id,
    categoryName: row.category_name,
    restaurantId: row.restaurant_id,
    restaurantName: row.restaurant_name,
    restaurantLogoUrl: row.restaurant_logo_url,
    restaurantCoverUrl: row.restaurant_cover_url,
    restaurantRating: Number(row.restaurant_rating || 4.6),
    ratingCount: Number(row.rating_count || 0),
    deliveryMinutesMin: Number(row.delivery_minutes_min || 25),
    deliveryMinutesMax: Number(row.delivery_minutes_max || 45),
    deliveryFee: Number(row.delivery_fee || 1.5),
    serviceFee: Number(row.service_fee || 0.35),
    commissionRate: Number(row.commission_rate || 0.18),
    minOrderAmount: Number(row.min_order_amount || 5.00),
    name: row.name,
    description: row.description,
    price: Number(row.price),
    originalPrice: row.original_price === null ? null : Number(row.original_price),
    discountPercent: Number(row.discount_percent || 0),
    stock: Number(row.stock),
    imageUrl: row.image_url,
    active: row.active,
    createdAt: row.created_at
  };
}

const productSelect = `
  SELECT p.*, c.name AS category_name,
         r.name AS restaurant_name, r.logo_url AS restaurant_logo_url, r.cover_url AS restaurant_cover_url,
         r.rating AS restaurant_rating, r.rating_count, r.delivery_minutes_min, r.delivery_minutes_max,
         r.delivery_fee, r.commission_rate, r.min_order_amount,
         COALESCE((SELECT value::numeric FROM app_settings WHERE key = 'service_fee'), 0.35) AS service_fee
  FROM products p
  LEFT JOIN categories c ON c.id = p.category_id
  LEFT JOIN restaurants r ON r.id = p.restaurant_id
`;

router.get('/', async (req, res, next) => {
  try {
    const search = req.query.search ? `%${req.query.search}%` : null;
    const result = await db.query(
      `${productSelect}
       WHERE p.active = TRUE
       AND ($1::TEXT IS NULL OR p.name ILIKE $1 OR p.description ILIKE $1 OR c.name ILIKE $1 OR r.name ILIKE $1)
       ORDER BY p.discount_percent DESC, p.created_at DESC`,
      [search]
    );
    return res.json({ products: result.rows.map(mapProduct) });
  } catch (error) {
    return next(error);
  }
});

router.get('/:id', async (req, res, next) => {
  try {
    const result = await db.query(
      `${productSelect}
       WHERE p.id = $1 AND p.active = TRUE`,
      [req.params.id]
    );
    if (result.rowCount === 0) return res.status(404).json({ message: 'Producto no encontrado.' });
    return res.json({ product: mapProduct(result.rows[0]) });
  } catch (error) {
    return next(error);
  }
});

router.post('/', requireAuth, allowRoles('admin'), validate(productSchema), async (req, res, next) => {
  try {
    const { restaurantId, categoryId, name, description, price, originalPrice, discountPercent, stock, imageUrl } = req.body;
    const result = await db.query(
      `INSERT INTO products (restaurant_id, category_id, name, description, price, original_price, discount_percent, stock, image_url)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
       RETURNING id`,
      [restaurantId || null, categoryId || null, name, description || null, price, originalPrice || null, discountPercent || 0, stock, imageUrl || null]
    );
    const created = await db.query(`${productSelect} WHERE p.id = $1`, [result.rows[0].id]);
    return res.status(201).json({ product: mapProduct(created.rows[0]) });
  } catch (error) {
    return next(error);
  }
});

router.put('/:id', requireAuth, allowRoles('admin'), validate(productSchema.partial()), async (req, res, next) => {
  try {
    const current = await db.query('SELECT * FROM products WHERE id = $1', [req.params.id]);
    if (current.rowCount === 0) return res.status(404).json({ message: 'Producto no encontrado.' });
    const old = current.rows[0];
    const data = req.body;
    const result = await db.query(
      `UPDATE products SET
        restaurant_id = $1,
        category_id = $2,
        name = $3,
        description = $4,
        price = $5,
        original_price = $6,
        discount_percent = $7,
        stock = $8,
        image_url = $9,
        updated_at = CURRENT_TIMESTAMP
       WHERE id = $10 RETURNING id`,
      [
        data.restaurantId !== undefined ? data.restaurantId : old.restaurant_id,
        data.categoryId !== undefined ? data.categoryId : old.category_id,
        data.name || old.name,
        data.description !== undefined ? data.description : old.description,
        data.price !== undefined ? data.price : old.price,
        data.originalPrice !== undefined ? data.originalPrice : old.original_price,
        data.discountPercent !== undefined ? data.discountPercent : old.discount_percent,
        data.stock !== undefined ? data.stock : old.stock,
        data.imageUrl !== undefined ? data.imageUrl : old.image_url,
        req.params.id
      ]
    );
    const updated = await db.query(`${productSelect} WHERE p.id = $1`, [result.rows[0].id]);
    return res.json({ product: mapProduct(updated.rows[0]) });
  } catch (error) {
    return next(error);
  }
});

router.delete('/:id', requireAuth, allowRoles('admin'), async (req, res, next) => {
  try {
    const result = await db.query(
      `UPDATE products SET active = FALSE, updated_at = CURRENT_TIMESTAMP WHERE id = $1 RETURNING id`,
      [req.params.id]
    );
    if (result.rowCount === 0) return res.status(404).json({ message: 'Producto no encontrado.' });
    return res.json({ message: 'Producto desactivado.' });
  } catch (error) {
    return next(error);
  }
});

module.exports = router;
