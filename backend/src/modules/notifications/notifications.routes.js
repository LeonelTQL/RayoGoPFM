const { Router } = require('express');
const { z } = require('zod');
const db = require('../../config/db');
const { requireAuth } = require('../../middlewares/auth.middleware');
const { validate } = require('../../middlewares/validate.middleware');

const router = Router();
const tokenSchema = z.object({ fcmToken: z.string().min(10) });

router.post('/token', requireAuth, validate(tokenSchema), async (req, res, next) => {
  try {
    await db.query('UPDATE users SET fcm_token = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2', [req.body.fcmToken, req.user.id]);
    return res.json({ message: 'Token de notificaciones guardado.' });
  } catch (error) {
    return next(error);
  }
});

module.exports = router;
