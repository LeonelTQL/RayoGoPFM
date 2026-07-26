process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test_secret_longer_than_32_characters_for_signing_tokens';

const request = require('supertest');
const app = require('../src/app');
const db = require('../src/config/db');

const testPassword = 'a'.repeat(60); // Satisface Zod min(60)
const { signUserToken } = require('../src/utils/token');

beforeAll(async () => {
  await db.initializeTestDb();
});

describe('Auth Endpoints', () => {
  let clientToken;
  let clientId;
  let adminToken;

  test('POST /api/auth/register should create a new client user', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({
        name: 'Ana Pérez',
        email: 'ana@example.com',
        password: testPassword,
        phone: '+593999999992'
      });
    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty('token');
    expect(res.body.user.email).toBe('ana@example.com');
    expect(res.body.user.role).toBe('cliente');
    
    clientToken = res.body.token;
    clientId = res.body.user.id;
  });

  test('POST /api/auth/register should return 409 on duplicate email', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({
        name: 'Ana López',
        email: 'ana@example.com',
        password: testPassword,
        phone: '+593999999992'
      });
    expect(res.status).toBe(409);
    expect(res.body.message).toContain('Ya existe');
  });

  test('POST /api/auth/login should return a token for valid credentials', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'ana@example.com',
        password: testPassword
      });
    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('token');
    expect(res.body.user.email).toBe('ana@example.com');
  });

  test('POST /api/auth/login should return 401 for incorrect credentials', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'ana@example.com',
        password: 'wrong_password_which_does_not_match_at_all'
      });
    expect(res.status).toBe(401);
  });

  test('POST /api/auth/login should return 401 for non-existent email', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'nobody@example.com',
        password: testPassword
      });
    expect(res.status).toBe(401);
  });

  test('GET /api/auth/me should return current user profile', async () => {
    const res = await request(app)
      .get('/api/auth/me')
      .set('Authorization', `Bearer ${clientToken}`);
    expect(res.status).toBe(200);
    expect(res.body.user.email).toBe('ana@example.com');
  });

  test('GET /api/auth/me should return 404 if user not found in database', async () => {
    // Manually delete the user from db to force 404
    await db.query('DELETE FROM users WHERE id = $1', [clientId]);

    const res = await request(app)
      .get('/api/auth/me')
      .set('Authorization', `Bearer ${clientToken}`);
    expect(res.status).toBe(404);

    // Recreate user for subsequent tests
    const registerRes = await request(app)
      .post('/api/auth/register')
      .send({
        name: 'Ana Pérez',
        email: 'ana@example.com',
        password: testPassword,
        phone: '+593999999992'
      });
    clientToken = registerRes.body.token;
    clientId = registerRes.body.user.id;
  });

  test('PUT /api/auth/update-phone should update the phone number', async () => {
    const res = await request(app)
      .put('/api/auth/update-phone')
      .set('Authorization', `Bearer ${clientToken}`)
      .send({ phone: '+593999999999' });
    expect(res.status).toBe(200);
    expect(res.body.user.phone).toBe('+593999999999');
  });

  test('PUT /api/auth/update-phone should return 400 for invalid phone number', async () => {
    const res = await request(app)
      .put('/api/auth/update-phone')
      .set('Authorization', `Bearer ${clientToken}`)
      .send({ phone: '123' });
    expect(res.status).toBe(400);
  });

  test('PUT /api/auth/change-password should update user password', async () => {
    const res = await request(app)
      .put('/api/auth/change-password')
      .set('Authorization', `Bearer ${clientToken}`)
      .send({
        currentPassword: testPassword,
        newPassword: 'b'.repeat(60)
      });
    expect(res.status).toBe(200);
    expect(res.body.message).toContain('Contraseña actualizada');
  });

  test('POST /api/auth/google-login should register or log in Google user', async () => {
    // New Google User
    const resNew = await request(app)
      .post('/api/auth/google-login')
      .send({
        email: 'googleuser@example.com',
        name: 'Google User',
        googleId: 'g123456',
        avatarUrl: 'http://avatar.url/image.png'
      });
    expect(resNew.status).toBe(200);
    expect(resNew.body.user.email).toBe('googleuser@example.com');
    expect(resNew.body.user.role).toBe('cliente');

    // Existing Google User Login
    const resExist = await request(app)
      .post('/api/auth/google-login')
      .send({
        email: 'googleuser@example.com',
        name: 'Google User',
        googleId: 'g123456'
      });
    expect(resExist.status).toBe(200);
  });

  test('POST /api/auth/change-role should fail if user is not admin', async () => {
    const res = await request(app)
      .post('/api/auth/change-role')
      .set('Authorization', `Bearer ${clientToken}`)
      .send({
        userId: clientId,
        newRole: 'repartidor'
      });
    expect(res.status).toBe(403);
  });

  test('POST /api/auth/change-role should succeed if user is admin', async () => {
    // Recreate a user with admin role manually in pg-mem
    const adminUser = await db.query(
      `INSERT INTO users (name, email, password_hash, phone, role)
       VALUES ($1, $2, $3, $4, 'admin') RETURNING *`,
      ['Admin', 'admin@smartdelivery.com', 'some_hash', '123456789']
    );
    const { signUserToken } = require('../src/utils/token');
    adminToken = signUserToken(adminUser.rows[0]);

    // Change role of client user to repartidor
    const res = await request(app)
      .post('/api/auth/change-role')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        userId: clientId,
        newRole: 'repartidor'
      });
    expect(res.status).toBe(200);
    expect(res.body.user.role).toBe('repartidor');
  });

  test('POST /api/auth/change-role should fail on invalid userId (NaN or undefined)', async () => {
    const res = await request(app)
      .post('/api/auth/change-role')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        userId: 'NaN',
        newRole: 'repartidor'
      });
    expect(res.status).toBe(400);
  });

  test('GET /api/auth/users should return all users for admin', async () => {
    const res = await request(app)
      .get('/api/auth/users')
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(200);
    expect(res.body.length).toBeGreaterThan(0);
  });

  test('DELETE /api/auth/delete-account should delete account and returns success', async () => {
    const res = await request(app)
      .delete('/api/auth/delete-account')
      .set('Authorization', `Bearer ${clientToken}`);
    expect(res.status).toBe(200);
    expect(res.body.message).toContain('Cuenta eliminada');
  });

  test('GET /health should return status ok', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });

  test('POST /api/auth/login with inactive user should fail', async () => {
    await db.query(
      `INSERT INTO users (name, email, password_hash, phone, role, active)
       VALUES ($1, $2, $3, $4, 'cliente', FALSE)`,
      ['Inactive', 'inactive@example.com', 'some_hash', '1234567']
    );

    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'inactive@example.com', password: 'password' });
    expect(res.status).toBe(403);
    expect(res.body.message).toContain('inactivo');

    const resGoogle = await request(app)
      .post('/api/auth/google-login')
      .send({
        email: 'inactive@example.com',
        name: 'Inactive',
        googleId: 'g123'
      });
    expect(resGoogle.status).toBe(403);
  });

  test('PUT /api/auth/change-password on Google user should not require currentPassword', async () => {
    const googleUserRes = await db.query(
      `INSERT INTO users (name, email, phone, role)
       VALUES ($1, $2, $3, 'cliente') RETURNING *`,
      ['Google User Pwd', 'googlepwd@example.com', '1234567']
    );
    const googleToken = signUserToken(googleUserRes.rows[0]);

    const res = await request(app)
      .put('/api/auth/change-password')
      .set('Authorization', `Bearer ${googleToken}`)
      .send({
        newPassword: 'c'.repeat(60)
      });
    expect(res.status).toBe(200);
    expect(res.body.message).toContain('Contraseña actualizada');
  });

  test('PUT /api/auth/change-password should return 400 if currentPassword is missing for local user', async () => {
    const localRes = await request(app)
      .post('/api/auth/register')
      .send({
        name: 'Local User',
        email: 'localpwd@example.com',
        password: testPassword,
        phone: '1234567'
      });
    const localToken = localRes.body.token;

    const res = await request(app)
      .put('/api/auth/change-password')
      .set('Authorization', `Bearer ${localToken}`)
      .send({
        newPassword: 'c'.repeat(60)
      });
    expect(res.status).toBe(400);
    expect(res.body.message).toContain('actual es obligatoria');
  });

  test('PUT /api/auth/change-password should return 400 for incorrect currentPassword', async () => {
    const localRes = await request(app)
      .post('/api/auth/login')
      .send({ email: 'localpwd@example.com', password: testPassword });
    const localToken = localRes.body.token;

    const res = await request(app)
      .put('/api/auth/change-password')
      .set('Authorization', `Bearer ${localToken}`)
      .send({
        currentPassword: 'wrong_password_which_does_not_match',
        newPassword: 'c'.repeat(60)
      });
    expect(res.status).toBe(400);
  });

  test('Auth endpoints should handle db errors in catch block', async () => {
    const originalQuery = db.query;
    db.query = jest.fn().mockImplementation((text, _params) => {
      if (text === 'BEGIN' || text === 'ROLLBACK' || text === 'COMMIT') {
        return Promise.resolve({ rowCount: 1, rows: [] });
      }
      return Promise.reject(new Error('DB failure'));
    });

    let res = await request(app)
      .get('/api/auth/users')
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(500);

    res = await request(app)
      .post('/api/auth/register')
      .send({
        name: 'Ana Pérez',
        email: 'ana-error@example.com',
        password: testPassword,
        phone: '+593999999992'
      });
    expect(res.status).toBe(500);

    res = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'ana-error@example.com',
        password: testPassword
      });
    expect(res.status).toBe(500);

    res = await request(app)
      .post('/api/auth/google-login')
      .send({
        email: 'google-err@example.com',
        name: 'Google User',
        googleId: 'g123'
      });
    expect(res.status).toBe(500);

    res = await request(app)
      .post('/api/auth/change-role')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        userId: clientId,
        newRole: 'repartidor'
      });
    expect(res.status).toBe(500);

    res = await request(app)
      .put('/api/auth/update-phone')
      .set('Authorization', `Bearer ${clientToken}`)
      .send({ phone: '999999999' });
    expect(res.status).toBe(500);

    res = await request(app)
      .put('/api/auth/change-password')
      .set('Authorization', `Bearer ${clientToken}`)
      .send({ currentPassword: testPassword, newPassword: 'c'.repeat(60) });
    expect(res.status).toBe(500);

    res = await request(app)
      .delete('/api/auth/delete-account')
      .set('Authorization', `Bearer ${clientToken}`);
    expect(res.status).toBe(500);

    db.query = originalQuery;
  });
});
