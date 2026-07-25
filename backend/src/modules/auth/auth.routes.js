const { Router } = require('express');
const bcrypt = require('bcryptjs');
const { z } = require('zod');
const db = require('../../config/db');
const { validate } = require('../../middlewares/validate.middleware');
const { requireAuth } = require('../../middlewares/auth.middleware');
const { signUserToken } = require('../../utils/token');

const router = Router();

// --- ESQUEMAS ---
const registerSchema = z.object({
  name: z.string().min(3, 'El nombre debe tener mínimo 3 caracteres.'),
  email: z.string().email('Correo inválido.').transform((value) => value.toLowerCase()),
  password: z.string().min(60, 'Error de seguridad.'),
  phone: z.string().min(7, 'Teléfono inválido.')
});

const googleLoginSchema = z.object({
  email: z.string().email(),
  name: z.string(),
  googleId: z.string(),
  avatarUrl: z.string().optional()
});

const changeRoleSchema = z.object({
  // Aceptamos cualquier cosa pero lo convertimos a String limpio
  userId: z.any().transform((v) => String(v)),
  newRole: z.enum(['cliente', 'repartidor'])
});

const loginSchema = z.object({
  email: z.string().email('Correo inválido.').transform((value) => value.toLowerCase()),
  password: z.string().min(1, 'La contraseña es obligatoria.')
});

const changePasswordSchema = z.object({
  currentPassword: z.string().optional(),
  newPassword: z.string().min(60, 'Error de seguridad.')
});

function publicUser(row) {
  return {
    id: row.id,
    name: row.name,
    email: row.email,
    phone: row.phone,
    role: row.role,
    avatarUrl: row.avatar_url,
    hasPassword: !!row.password_hash
  };
}

// --- RUTAS ---

router.post('/register', validate(registerSchema), async (req, res, next) => {
  try {
    const { name, email, password, phone } = req.body;
    const exists = await db.query('SELECT id FROM users WHERE email = $1', [email]);
    if (exists.rowCount > 0) return res.status(409).json({ message: 'Ya existe este correo.' });

    const passwordHash = await bcrypt.hash(password, 10);
    const result = await db.query(
      `INSERT INTO users (name, email, password_hash, phone, role)
       VALUES ($1, $2, $3, $4, 'cliente')
       RETURNING *`,
      [name, email, passwordHash, phone]
    );

    const user = publicUser(result.rows[0]);
    return res.status(201).json({ token: signUserToken(user), user });
  } catch (e) { next(e); }
});

router.post('/google-login', validate(googleLoginSchema), async (req, res, next) => {
  try {
    const { email, name, avatarUrl } = req.body;
    let result = await db.query('SELECT * FROM users WHERE email = $1', [email]);
    let userRow;

    if (result.rowCount === 0) {
      const ins = await db.query(
        `INSERT INTO users (name, email, avatar_url, role, active, phone)
         VALUES ($1, $2, $3, 'cliente', TRUE, '') RETURNING *`,
        [name, email, avatarUrl]
      );
      userRow = ins.rows[0];
    } else {
      userRow = result.rows[0];
      if (!userRow.active) return res.status(403).json({ message: 'Usuario inactivo.' });
    }

    const user = publicUser(userRow);
    return res.json({ token: signUserToken(user), user });
  } catch (e) { next(e); }
});

router.post('/change-role', requireAuth, validate(changeRoleSchema), async (req, res, next) => {
  try {
    if (req.user.role !== 'admin') return res.status(403).json({ message: 'No autorizado.' });

    const { userId, newRole } = req.body;

    // Protección absoluta contra el error NaN
    if (!userId || userId === "NaN" || userId === "undefined") {
      return res.status(400).json({ message: 'ID de usuario inválido (NaN detectado).' });
    }

    const result = await db.query(
      'UPDATE users SET role = $1 WHERE id = $2 RETURNING *',
      [newRole, userId]
    );

    if (result.rowCount === 0) return res.status(404).json({ message: 'Usuario no encontrado.' });

    return res.json({ message: 'Rol actualizado.', user: publicUser(result.rows[0]) });
  } catch (e) {
    console.error("Error en DB:", e.message);
    next(e);
  }
});

router.put('/update-phone', requireAuth, async (req, res, next) => {
  try {
    const { phone } = req.body;
    if (!phone || phone.trim().length < 7) {
      return res.status(400).json({ message: 'Teléfono inválido. Debe tener al menos 7 dígitos.' });
    }
    const result = await db.query(
      'UPDATE users SET phone = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
      [phone.trim(), req.user.id]
    );
    if (result.rowCount === 0) return res.status(404).json({ message: 'Usuario no encontrado.' });
    return res.json({ message: 'Teléfono actualizado.', user: publicUser(result.rows[0]) });
  } catch (e) { next(e); }
});

router.put('/change-password', requireAuth, validate(changePasswordSchema), async (req, res, next) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const result = await db.query('SELECT * FROM users WHERE id = $1', [req.user.id]);
    if (result.rowCount === 0) return res.status(404).json({ message: 'Usuario no encontrado.' });
    const row = result.rows[0];

    if (row.password_hash) {
      if (!currentPassword) {
        return res.status(400).json({ message: 'La contraseña actual es obligatoria.' });
      }
      const ok = await bcrypt.compare(currentPassword, row.password_hash);
      if (!ok) return res.status(400).json({ message: 'La contraseña actual es incorrecta.' });
    }

    const newPasswordHash = await bcrypt.hash(newPassword, 10);
    await db.query(
      'UPDATE users SET password_hash = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
      [newPasswordHash, req.user.id]
    );

    const userResult = await db.query('SELECT * FROM users WHERE id = $1', [req.user.id]);
    return res.json({ message: 'Contraseña actualizada correctamente.', user: publicUser(userResult.rows[0]) });
  } catch (e) { next(e); }
});

router.delete('/delete-account', requireAuth, async (req, res, next) => {
  const userId = req.user.id;
  try {
    await db.query('BEGIN');
    
    // 1. Delete delivery locations and proofs where rider_id matches
    await db.query('DELETE FROM delivery_locations WHERE rider_id = $1', [userId]);
    await db.query('DELETE FROM delivery_proofs WHERE rider_id = $1', [userId]);
    
    // 2. Delete orders (and their cascading items/payments) where user is customer or rider
    await db.query('DELETE FROM orders WHERE customer_id = $1 OR rider_id = $1', [userId]);
    
    // 3. Delete addresses where user_id matches
    await db.query('DELETE FROM addresses WHERE user_id = $1', [userId]);
    
    // 4. Delete the user
    const result = await db.query('DELETE FROM users WHERE id = $1 RETURNING id', [userId]);
    
    await db.query('COMMIT');
    
    if (result.rowCount === 0) {
      return res.status(404).json({ message: 'Usuario no encontrado.' });
    }
    
    return res.json({ message: 'Cuenta eliminada y todos los datos asociados han sido borrados.' });
  } catch (e) {
    await db.query('ROLLBACK');
    console.error("Error al eliminar cuenta:", e.message);
    next(e);
  }
});

router.post('/login', validate(loginSchema), async (req, res, next) => {
  try {
    const { email, password } = req.body;
    const result = await db.query('SELECT * FROM users WHERE email = $1', [email]);

    if (result.rowCount === 0) return res.status(401).json({ message: 'Credenciales incorrectas.' });
    const row = result.rows[0];
    if (!row.active) return res.status(403).json({ message: 'Usuario inactivo.' });

    const ok = await bcrypt.compare(password, row.password_hash || '');
    if (!ok) return res.status(401).json({ message: 'Credenciales incorrectas.' });

    const user = publicUser(row);
    return res.json({ token: signUserToken(user), user });
  } catch (e) { next(e); }
});

router.get('/me', requireAuth, async (req, res, next) => {
  try {
    const result = await db.query('SELECT * FROM users WHERE id = $1', [req.user.id]);
    if (result.rowCount === 0) return res.status(404).json({ message: 'No encontrado.' });
    return res.json({ user: publicUser(result.rows[0]) });
  } catch (e) { next(e); }
});

router.get('/users', requireAuth, async (req, res, next) => {
  try {
    if (req.user.role !== 'admin') return res.status(403).json({ message: 'No autorizado.' });
    const result = await db.query('SELECT * FROM users ORDER BY name ASC');
    return res.json(result.rows.map(publicUser));
  } catch (e) { next(e); }
});

module.exports = router;
