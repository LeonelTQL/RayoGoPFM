const { Router } = require('express');
const { z } = require('zod');
const db = require('../../config/db');
const { requireAuth } = require('../../middlewares/auth.middleware');
const { allowRoles } = require('../../middlewares/role.middleware');
const { validate } = require('../../middlewares/validate.middleware');

const router = Router();
const categorySchema = z.object({ name: z.string().min(2, 'Nombre requerido.') });

router.get('/', async (req, res, next) => {
  try {
    const result = await db.query(
      `SELECT id, name, active, created_at FROM categories WHERE active = TRUE ORDER BY name ASC`
    );
    return res.json({ categories: result.rows });
  } catch (error) {
    return next(error);
  }
});

router.post('/', requireAuth, allowRoles('admin'), validate(categorySchema), async (req, res, next) => {
  try {
    const result = await db.query(
      `INSERT INTO categories (name) VALUES ($1)
       ON CONFLICT (name) DO UPDATE SET active = TRUE
       RETURNING id, name, active`,
      [req.body.name]
    );
    return res.status(201).json({ category: result.rows[0] });
  } catch (error) {
    return next(error);
  }
});

module.exports = router;
