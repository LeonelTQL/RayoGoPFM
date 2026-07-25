const { Router } = require('express');
const { z } = require('zod');
const db = require('../../config/db');
const { requireAuth } = require('../../middlewares/auth.middleware');
const { allowRoles } = require('../../middlewares/role.middleware');
const { validate } = require('../../middlewares/validate.middleware');

const router = Router();
const DEFAULT_MIN_ORDER_AMOUNT = 5.00;
const DEFAULT_SERVICE_FEE = 0.35;

const { getIO } = require('../../config/socket');

async function getNumericSetting(key, fallback) {
  const result = await db.query('SELECT value FROM app_settings WHERE key = $1', [key]);
  if (result.rowCount === 0) return fallback;
  const value = Number(result.rows[0].value);
  return Number.isFinite(value) ? value : fallback;
}

const createOrderSchema = z.object({
  deliveryAddressId: z.string().uuid('Dirección inválida.'),
  paymentMethod: z.enum(['efectivo', 'transferencia', 'comprobante']),
  note: z.string().optional().nullable(),
  items: z.array(z.object({
    productId: z.string().uuid('Producto inválido.'),
    quantity: z.number().int().min(1, 'La cantidad debe ser mayor a 0.')
  })).min(1, 'El carrito no puede estar vacío.')
});

const updateStatusSchema = z.object({
  status: z.enum(['pendiente', 'confirmado', 'preparando', 'asignado', 'en_camino', 'entregado', 'cancelado'])
});

const assignSchema = z.object({ riderId: z.string().uuid('Repartidor inválido.') });

function mapOrder(row) {
  return {
    id: row.id,
    customerId: row.customer_id,
    customerName: row.customer_name,
    riderId: row.rider_id,
    riderName: row.rider_name,
    restaurantId: row.restaurant_id,
    restaurantName: row.restaurant_name,
    deliveryAddressId: row.delivery_address_id,
    addressLine: row.address_line,
    latitude: row.latitude === null ? null : Number(row.latitude),
    longitude: row.longitude === null ? null : Number(row.longitude),
    status: row.status,
    subtotal: Number(row.subtotal),
    deliveryFee: Number(row.delivery_fee),
    serviceFee: Number(row.service_fee || 0),
    restaurantCommission: Number(row.restaurant_commission || 0),
    restaurantPayout: Number(row.restaurant_payout || 0),
    total: Number(row.total),
    paymentMethod: row.payment_method,
    paymentStatus: row.payment_status,
    note: row.note,
    createdAt: row.created_at,
    updatedAt: row.updated_at
  };
}

async function fetchOrderDetails(orderId) {
  const orderResult = await db.query(
    `SELECT o.*, c.name AS customer_name, r.name AS rider_name, a.address_line, a.latitude, a.longitude, res.name AS restaurant_name
     FROM orders o
     INNER JOIN users c ON c.id = o.customer_id
     LEFT JOIN users r ON r.id = o.rider_id
     LEFT JOIN addresses a ON a.id = o.delivery_address_id
     LEFT JOIN restaurants res ON res.id = o.restaurant_id
     WHERE o.id = $1`,
    [orderId]
  );
  if (orderResult.rowCount === 0) return null;

  const itemsResult = await db.query(
    `SELECT id, order_id, product_id, product_name, quantity, unit_price, total
     FROM order_items
     WHERE order_id = $1`,
    [orderId]
  );
  return {
    ...mapOrder(orderResult.rows[0]),
    items: itemsResult.rows.map((item) => ({
      id: item.id,
      orderId: item.order_id,
      productId: item.product_id,
      productName: item.product_name,
      quantity: Number(item.quantity),
      unitPrice: Number(item.unit_price),
      total: Number(item.total)
    }))
  };
}

router.post('/', requireAuth, allowRoles('cliente'), validate(createOrderSchema), async (req, res, next) => {
  const client = await db.pool.connect();
  try {
    const { deliveryAddressId, paymentMethod, note, items } = req.body;
    await client.query('BEGIN');

    const addressResult = await client.query(
      `SELECT id FROM addresses WHERE id = $1 AND user_id = $2`,
      [deliveryAddressId, req.user.id]
    );
    if (addressResult.rowCount === 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ message: 'La dirección no pertenece al usuario.' });
    }

    let subtotal = 0;
    const dbItems = [];
    let restaurantId = null;
    let deliveryFee = 1.50;
    let commissionRate = 0.18;
    let minOrder = DEFAULT_MIN_ORDER_AMOUNT;
    const serviceFee = await getNumericSetting('service_fee', DEFAULT_SERVICE_FEE);

    for (const item of items) {
      const productResult = await client.query(
        `SELECT p.id, p.name, p.price, p.stock, p.active, p.restaurant_id,
                COALESCE(r.delivery_fee, 1.50) AS delivery_fee,
                COALESCE(r.commission_rate, 0.18) AS commission_rate,
                COALESCE(r.min_order_amount, 5.00) AS min_order_amount
         FROM products p
         LEFT JOIN restaurants r ON r.id = p.restaurant_id
         WHERE p.id = $1 FOR UPDATE OF p`,
        [item.productId]
      );

      if (productResult.rowCount === 0 || !productResult.rows[0].active) {
        await client.query('ROLLBACK');
        return res.status(404).json({ message: `Producto no disponible: ${item.productId}` });
      }

      const product = productResult.rows[0];
      if (restaurantId === null) {
        restaurantId = product.restaurant_id;
        deliveryFee = Number(product.delivery_fee);
        commissionRate = Number(product.commission_rate);
        minOrder = Number(product.min_order_amount);
      } else if (product.restaurant_id !== restaurantId) {
        await client.query('ROLLBACK');
        return res.status(400).json({ message: 'Solo se permite un restaurante/local por pedido.' });
      }

      if (Number(product.stock) < item.quantity) {
        await client.query('ROLLBACK');
        return res.status(400).json({ message: `Stock insuficiente para ${product.name}.` });
      }

      const unitPrice = Number(product.price);
      const total = unitPrice * item.quantity;
      subtotal += total;
      dbItems.push({ product, quantity: item.quantity, unitPrice, total });
    }

    if (subtotal < minOrder) {
      await client.query('ROLLBACK');
      return res.status(400).json({ message: `El subtotal mínimo para registrar el pedido es $${minOrder.toFixed(2)}.` });
    }

    const restaurantCommission = Number((subtotal * commissionRate).toFixed(2));
    const restaurantPayout = Number((subtotal - restaurantCommission).toFixed(2));
    const total = Number((subtotal + deliveryFee + serviceFee).toFixed(2));

    const orderResult = await client.query(
      `INSERT INTO orders (customer_id, delivery_address_id, restaurant_id, subtotal, delivery_fee, service_fee, restaurant_commission, restaurant_payout, total, payment_method, payment_status, note)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,'pendiente',$11)
       RETURNING id`,
      [req.user.id, deliveryAddressId, restaurantId, subtotal.toFixed(2), deliveryFee, serviceFee, restaurantCommission, restaurantPayout, total, paymentMethod, note || null]
    );

    const orderId = orderResult.rows[0].id;
    for (const item of dbItems) {
      await client.query(
        `INSERT INTO order_items (order_id, product_id, product_name, quantity, unit_price, total)
         VALUES ($1,$2,$3,$4,$5,$6)`,
        [orderId, item.product.id, item.product.name, item.quantity, item.unitPrice, item.total]
      );
      await client.query(`UPDATE products SET stock = stock - $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2`, [item.quantity, item.product.id]);
    }

    await client.query(`INSERT INTO payments (order_id, method, amount, status) VALUES ($1,$2,$3,'pendiente')`, [orderId, paymentMethod, total]);
    await client.query('COMMIT');
    const order = await fetchOrderDetails(orderId);

    // Notificar a todos los repartidores sobre el nuevo pedido
    try {
      getIO().to('role:repartidor').emit('new_order_available', { order });
    } catch (ioError) {
      console.error('Error emitting new_order_available:', ioError);
    }

    return res.status(201).json({ order });
  } catch (error) {
    await client.query('ROLLBACK');
    return next(error);
  } finally {
    client.release();
  }
});

router.get('/my-orders', requireAuth, allowRoles('cliente'), async (req, res, next) => {
  try {
    const result = await db.query(
      `SELECT o.*, c.name AS customer_name, r.name AS rider_name, a.address_line, a.latitude, a.longitude, res.name AS restaurant_name
       FROM orders o
       INNER JOIN users c ON c.id = o.customer_id
       LEFT JOIN users r ON r.id = o.rider_id
       LEFT JOIN addresses a ON a.id = o.delivery_address_id
       LEFT JOIN restaurants res ON res.id = o.restaurant_id
       WHERE o.customer_id = $1
       ORDER BY o.created_at DESC`,
      [req.user.id]
    );
    return res.json({ orders: result.rows.map(mapOrder) });
  } catch (error) { return next(error); }
});

router.get('/admin/all', requireAuth, allowRoles('admin', 'repartidor'), async (req, res, next) => {
  try {
    let query = `SELECT o.*, c.name AS customer_name, r.name AS rider_name, a.address_line, a.latitude, a.longitude, res.name AS restaurant_name
       FROM orders o
       INNER JOIN users c ON c.id = o.customer_id
       LEFT JOIN users r ON r.id = o.rider_id
       LEFT JOIN addresses a ON a.id = o.delivery_address_id
       LEFT JOIN restaurants res ON res.id = o.restaurant_id`;

    const params = [];
    if (req.user.role === 'repartidor') {
      query += ` WHERE o.status = 'pendiente'`;
    }

    query += ` ORDER BY o.created_at DESC`;

    const result = await db.query(query, params);
    return res.json({ orders: result.rows.map(mapOrder) });
  } catch (error) { return next(error); }
});

router.get('/riders', requireAuth, allowRoles('admin'), async (req, res, next) => {
  try {
    const result = await db.query(`SELECT id, name, email, phone, role FROM users WHERE role = 'repartidor' AND active = TRUE ORDER BY name`);
    return res.json({ riders: result.rows });
  } catch (error) { return next(error); }
});

router.get('/:id', requireAuth, async (req, res, next) => {
  try {
    const order = await fetchOrderDetails(req.params.id);
    if (!order) return res.status(404).json({ message: 'Pedido no encontrado.' });
    const canRead = req.user.role === 'admin' || order.customerId === req.user.id || order.riderId === req.user.id;
    if (!canRead) return res.status(403).json({ message: 'No puedes ver este pedido.' });
    return res.json({ order });
  } catch (error) { return next(error); }
});

router.patch('/:id/accept', requireAuth, allowRoles('repartidor'), async (req, res, next) => {
  const client = await db.pool.connect();
  try {
    await client.query('BEGIN');

    // Verificar si el pedido sigue disponible (sin rider_id y estado pendiente)
    const checkResult = await client.query(
      `SELECT status, rider_id FROM orders WHERE id = $1 FOR UPDATE`,
      [req.params.id]
    );

    if (checkResult.rowCount === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ message: 'Pedido no encontrado.' });
    }

    const order = checkResult.rows[0];
    if (order.rider_id !== null || order.status !== 'pendiente') {
      await client.query('ROLLBACK');
      return res.status(400).json({ message: 'Este pedido ya no está disponible o ya fue aceptado.' });
    }

    // Asignar el pedido al repartidor actual
    await client.query(
      `UPDATE orders SET rider_id = $1, status = 'asignado', updated_at = CURRENT_TIMESTAMP WHERE id = $2`,
      [req.user.id, req.params.id]
    );

    await client.query('COMMIT');

    const updatedOrder = await fetchOrderDetails(req.params.id);

    // Notificar a todos los repartidores que el pedido ya no está disponible
    getIO().to('role:repartidor').emit('order_taken', { orderId: req.params.id });

    // Notificar al cliente que su pedido fue aceptado
    getIO().to(`user:${updatedOrder.customerId}`).emit('order_accepted', { order: updatedOrder });

    return res.json({ order: updatedOrder });
  } catch (error) {
    await client.query('ROLLBACK');
    return next(error);
  } finally {
    client.release();
  }
});

router.patch('/:id/status', requireAuth, validate(updateStatusSchema), async (req, res, next) => {
  try {
    const existing = await db.query('SELECT * FROM orders WHERE id = $1', [req.params.id]);
    if (existing.rowCount === 0) return res.status(404).json({ message: 'Pedido no encontrado.' });

    const order = existing.rows[0];
    if (req.user.role === 'cliente') return res.status(403).json({ message: 'El cliente no puede cambiar estados.' });
    if (req.user.role === 'repartidor' && order.rider_id !== req.user.id) return res.status(403).json({ message: 'Pedido no asignado a este repartidor.' });
    if (req.user.role === 'repartidor' && !['en_camino', 'entregado'].includes(req.body.status)) return res.status(403).json({ message: 'El repartidor solo puede marcar en camino o entregado.' });

    const result = await db.query(`UPDATE orders SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING id`, [req.body.status, req.params.id]);
    const updated = await fetchOrderDetails(result.rows[0].id);

    // NOTIFICACIÓN: Avisar al cliente del cambio de estado
    try {
      getIO().to(`user:${updated.customerId}`).emit('order_status_updated', {
        orderId: updated.id,
        status: updated.status
      });
    } catch (ioError) {
      console.error('Error enviando notificación de estado:', ioError);
    }

    return res.json({ order: updated });
  } catch (error) { return next(error); }
});

router.patch('/:id/assign', requireAuth, allowRoles('admin'), validate(assignSchema), async (req, res, next) => {
  try {
    const rider = await db.query(`SELECT id FROM users WHERE id = $1 AND role = 'repartidor' AND active = TRUE`, [req.body.riderId]);
    if (rider.rowCount === 0) return res.status(400).json({ message: 'Repartidor no válido.' });
    const result = await db.query(
      `UPDATE orders SET rider_id = $1, status = 'asignado', updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING id`,
      [req.body.riderId, req.params.id]
    );
    if (result.rowCount === 0) return res.status(404).json({ message: 'Pedido no encontrado.' });
    const updated = await fetchOrderDetails(result.rows[0].id);
    return res.json({ order: updated });
  } catch (error) { return next(error); }
});

module.exports = router;
