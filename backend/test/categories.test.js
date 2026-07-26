process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test_secret_longer_than_32_characters_for_signing_tokens';

const request = require('supertest');
const app = require('../src/app');
const db = require('../src/config/db');
const { signUserToken } = require('../src/utils/token');

beforeAll(async () => {
  await db.initializeTestDb();
});

describe('Categories Endpoints', () => {
  let clientToken;
  let adminToken;

  beforeAll(() => {
    clientToken = signUserToken({ id: 'client-123', email: 'client@example.com', name: 'Client', role: 'cliente' });
    adminToken = signUserToken({ id: 'admin-123', email: 'admin@example.com', name: 'Admin', role: 'admin' });
  });

  test('GET /api/categories should return active categories', async () => {
    const res = await request(app).get('/api/categories');
    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('categories');
    expect(Array.isArray(res.body.categories)).toBe(true);
  });

  test('POST /api/categories should fail if user is not admin', async () => {
    const res = await request(app)
      .post('/api/categories')
      .set('Authorization', `Bearer ${clientToken}`)
      .send({ name: 'Fast Food' });
    expect(res.status).toBe(403);
  });

  test('POST /api/categories should succeed if user is admin', async () => {
    const res = await request(app)
      .post('/api/categories')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ name: 'Fast Food' });
    expect(res.status).toBe(201);
    expect(res.body.category.name).toBe('Fast Food');
  });

  test('POST /api/categories should handle conflict on duplicate name by updating active status', async () => {
    // Disable it first
    await db.query("UPDATE categories SET active = FALSE WHERE name = 'Fast Food'");

    const res = await request(app)
      .post('/api/categories')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ name: 'Fast Food' });
    expect(res.status).toBe(201);
    expect(res.body.category.active).toBe(true);
  });

  test('Categories endpoints should handle db errors in catch block', async () => {
    const originalQuery = db.query;
    db.query = jest.fn().mockRejectedValue(new Error('DB failure'));

    let res = await request(app).get('/api/categories');
    expect(res.status).toBe(500);

    res = await request(app)
      .post('/api/categories')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ name: 'Desserts' });
    expect(res.status).toBe(500);

    db.query = originalQuery;
  });
});
