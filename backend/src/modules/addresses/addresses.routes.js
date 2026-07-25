const { Router } = require('express');
const { z } = require('zod');
const db = require('../../config/db');
const { requireAuth } = require('../../middlewares/auth.middleware');
const { validate } = require('../../middlewares/validate.middleware');

const router = Router();

const addressSchema = z.object({
  label: z.string().min(2, 'Etiqueta requerida.'),
  addressLine: z.string().min(5, 'Dirección requerida.'),
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  isDefault: z.boolean().default(false)
});

function mapAddress(row) {
  return {
    id: row.id,
    userId: row.user_id,
    label: row.label,
    addressLine: row.address_line,
    latitude: Number(row.latitude),
    longitude: Number(row.longitude),
    isDefault: row.is_default
  };
}

router.get('/', requireAuth, async (req, res, next) => {
  try {
    const result = await db.query(
      `SELECT * FROM addresses WHERE user_id = $1 ORDER BY is_default DESC, created_at DESC`,
      [req.user.id]
    );
    return res.json({ addresses: result.rows.map(mapAddress) });
  } catch (error) {
    return next(error);
  }
});

router.post('/', requireAuth, validate(addressSchema), async (req, res, next) => {
  const client = await db.pool.connect();
  try {
    const { label, addressLine, latitude, longitude, isDefault } = req.body;
    await client.query('BEGIN');
    if (isDefault) {
      await client.query('UPDATE addresses SET is_default = FALSE WHERE user_id = $1', [req.user.id]);
    }
    const result = await client.query(
      `INSERT INTO addresses (user_id, label, address_line, latitude, longitude, is_default)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [req.user.id, label, addressLine, latitude, longitude, isDefault]
    );
    await client.query('COMMIT');
    return res.status(201).json({ address: mapAddress(result.rows[0]) });
  } catch (error) {
    await client.query('ROLLBACK');
    return next(error);
  } finally {
    client.release();
  }
});

router.delete('/:id', requireAuth, async (req, res, next) => {
  try {
    const result = await db.query('DELETE FROM addresses WHERE id = $1 AND user_id = $2 RETURNING id', [req.params.id, req.user.id]);
    if (result.rowCount === 0) return res.status(404).json({ message: 'Dirección no encontrada.' });
    return res.json({ message: 'Dirección eliminada.' });
  } catch (error) {
    return next(error);
  }
});

module.exports = router;
