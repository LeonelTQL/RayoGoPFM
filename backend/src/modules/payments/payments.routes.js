const { Router } = require('express');
const { z } = require('zod');
const db = require('../../config/db');
const { requireAuth } = require('../../middlewares/auth.middleware');
const { allowRoles } = require('../../middlewares/role.middleware');
const { validate } = require('../../middlewares/validate.middleware');
const { upload, buildFileUrl } = require('../../config/upload');

const router = Router();
const validatePaymentSchema = z.object({ status: z.enum(['aprobado', 'rechazado']) });

router.post('/:orderId/proof', requireAuth, allowRoles('cliente'), upload.single('image'), async (req, res, next) => {
  try {
    const { orderId } = req.params;
    const order = await db.query(
      `SELECT id FROM orders WHERE id = $1 AND customer_id = $2`,
      [orderId, req.user.id]
    );
    if (order.rowCount === 0) return res.status(404).json({ message: 'Pedido no encontrado.' });
    if (!req.file) return res.status(400).json({ message: 'La imagen del comprobante es obligatoria.' });

    const imageUrl = buildFileUrl(req, req.file.filename);
    const result = await db.query(
      `UPDATE payments
       SET proof_image_url = $1, transaction_reference = $2, status = 'pendiente', updated_at = CURRENT_TIMESTAMP
       WHERE order_id = $3
       RETURNING id, order_id, method, status, amount, proof_image_url, transaction_reference`,
      [imageUrl, req.body.transactionReference || null, orderId]
    );
    return res.json({ payment: result.rows[0] });
  } catch (error) {
    return next(error);
  }
});

router.patch('/:id/validate', requireAuth, allowRoles('admin'), validate(validatePaymentSchema), async (req, res, next) => {
  try {
    const result = await db.query(
      `UPDATE payments SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *`,
      [req.body.status, req.params.id]
    );
    if (result.rowCount === 0) return res.status(404).json({ message: 'Pago no encontrado.' });
    await db.query(
      `UPDATE orders SET payment_status = $1, status = CASE WHEN $1 = 'aprobado' AND status = 'pendiente' THEN 'confirmado' ELSE status END, updated_at = CURRENT_TIMESTAMP
       WHERE id = $2`,
      [req.body.status, result.rows[0].order_id]
    );
    return res.json({ payment: result.rows[0] });
  } catch (error) {
    return next(error);
  }
});

module.exports = router;
