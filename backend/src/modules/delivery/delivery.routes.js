const { Router } = require('express');
const { z } = require('zod');
const db = require('../../config/db');
const { requireAuth } = require('../../middlewares/auth.middleware');
const { allowRoles } = require('../../middlewares/role.middleware');
const { validate } = require('../../middlewares/validate.middleware');
const { upload, buildFileUrl } = require('../../config/upload');

const router = Router();

const locationSchema = z.object({
  orderId: z.string().uuid(),
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  accuracy: z.number().nullable().optional()
});

function mapOrder(row) {
  return {
    id: row.id,
    customerName: row.customer_name,
    addressLine: row.address_line,
    latitude: row.latitude === null ? null : Number(row.latitude),
    longitude: row.longitude === null ? null : Number(row.longitude),
    status: row.status,
    total: Number(row.total),
    paymentMethod: row.payment_method,
    paymentStatus: row.payment_status,
    createdAt: row.created_at
  };
}

router.get('/orders', requireAuth, allowRoles('repartidor'), async (req, res, next) => {
  try {
    const result = await db.query(
      `SELECT o.*, c.name AS customer_name, a.address_line, a.latitude, a.longitude
       FROM orders o
       INNER JOIN users c ON c.id = o.customer_id
       LEFT JOIN addresses a ON a.id = o.delivery_address_id
       WHERE o.rider_id = $1
       ORDER BY o.created_at DESC`,
      [req.user.id]
    );
    return res.json({ orders: result.rows.map(mapOrder) });
  } catch (error) {
    return next(error);
  }
});

const { getIO } = require('../../config/socket');

// Función para calcular distancia (Haversine)
function getDistance(lat1, lon1, lat2, lon2) {
  const R = 6371e3; // Metros
  const φ1 = lat1 * Math.PI / 180;
  const φ2 = lat2 * Math.PI / 180;
  const Δφ = (lat2 - lat1) * Math.PI / 180;
  const Δλ = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
            Math.cos(φ1) * Math.cos(φ2) *
            Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

router.post('/location', requireAuth, allowRoles('repartidor'), validate(locationSchema), async (req, res, next) => {
  try {
    const { orderId, latitude, longitude, accuracy } = req.body;

    // Obtener el pedido y la ubicación de destino
    const orderResult = await db.query(
      `SELECT o.id, o.customer_id, a.latitude as dest_lat, a.longitude as dest_lng
       FROM orders o
       JOIN addresses a ON o.delivery_address_id = a.id
       WHERE o.id = $1 AND o.rider_id = $2`,
      [orderId, req.user.id]
    );

    if (orderResult.rowCount === 0) {
      return res.status(403).json({ message: 'Pedido no asignado.' });
    }

    const order = orderResult.rows[0];

    // Insertar ubicación actual
    const result = await db.query(
      `INSERT INTO delivery_locations (order_id, rider_id, latitude, longitude, accuracy)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [orderId, req.user.id, latitude, longitude, accuracy || null]
    );

    // LÓGICA DE PROXIMIDAD: Si está a menos de 500 metros, notificar
    const distance = getDistance(latitude, longitude, order.dest_lat, order.dest_lng);

    if (distance < 500) {
      getIO().to(`user:${order.customer_id}`).emit('rider_nearby', {
        orderId,
        distance: Math.round(distance)
      });
    }

    // Emitir ubicación en tiempo real para el mapa del cliente
    getIO().to(`user:${order.customer_id}`).emit('location_update', {
      orderId,
      latitude,
      longitude
    });

    return res.status(201).json({ location: result.rows[0] });
  } catch (error) {
    return next(error);
  }
});

router.get('/location/:orderId', requireAuth, async (req, res, next) => {
  try {
    const orderResult = await db.query('SELECT customer_id, rider_id FROM orders WHERE id = $1', [req.params.orderId]);
    if (orderResult.rowCount === 0) return res.status(404).json({ message: 'Pedido no encontrado.' });

    const order = orderResult.rows[0];
    const canRead = req.user.role === 'admin' || order.customer_id === req.user.id || order.rider_id === req.user.id;
    if (!canRead) return res.status(403).json({ message: 'No puedes consultar esta ubicación.' });

    const result = await db.query(
      `SELECT id, order_id, rider_id, latitude, longitude, accuracy, created_at
       FROM delivery_locations
       WHERE order_id = $1
       ORDER BY created_at DESC
       LIMIT 1`,
      [req.params.orderId]
    );
    return res.json({ location: result.rows[0] || null });
  } catch (error) {
    return next(error);
  }
});

router.post('/proof', requireAuth, allowRoles('repartidor'), upload.single('image'), async (req, res, next) => {
  try {
    const { orderId, note } = req.body;
    if (!orderId) return res.status(400).json({ message: 'orderId es obligatorio.' });
    if (!req.file) return res.status(400).json({ message: 'La foto de comprobante es obligatoria.' });

    const assigned = await db.query(
      `SELECT id, payment_method FROM orders WHERE id = $1 AND rider_id = $2`,
      [orderId, req.user.id]
    );
    if (assigned.rowCount === 0) return res.status(403).json({ message: 'Pedido no asignado a este repartidor.' });

    const imageUrl = buildFileUrl(req, req.file.filename);
    const result = await db.query(
      `INSERT INTO delivery_proofs (order_id, rider_id, image_url, note)
       VALUES ($1, $2, $3, $4)
       RETURNING id, order_id, rider_id, image_url, note, delivered_at`,
      [orderId, req.user.id, imageUrl, note || null]
    );

    await db.query(
      `UPDATE orders
       SET status = 'entregado', payment_status = CASE WHEN payment_method = 'efectivo' THEN 'aprobado' ELSE payment_status END, updated_at = CURRENT_TIMESTAMP
       WHERE id = $1`,
      [orderId]
    );

    return res.status(201).json({ proof: result.rows[0] });
  } catch (error) {
    return next(error);
  }
});

module.exports = router;
