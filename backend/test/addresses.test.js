process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test_secret_longer_than_32_characters_for_signing_tokens';

const request = require('supertest');
const app = require('../src/app');
const db = require('../src/config/db');
const { signUserToken } = require('../src/utils/token');

beforeAll(async () => {
  await db.initializeTestDb();
});

describe('Addresses Endpoints', () => {
  let clientToken;
  let addressId;

  beforeAll(async () => {
    const userRes = await db.query(
      `INSERT INTO users (name, email, password_hash, phone, role)
       VALUES ($1, $2, $3, $4, 'cliente') RETURNING *`,
      ['Leonel Address Client', 'addressclient@example.com', 'some_hash', '987654321']
    );
    clientToken = signUserToken(userRes.rows[0]);
  });

  test('GET /api/addresses should return empty array initially', async () => {
    const res = await request(app)
      .get('/api/addresses')
      .set('Authorization', `Bearer ${clientToken}`);
    expect(res.status).toBe(200);
    expect(res.body.addresses).toEqual([]);
  });

  test('POST /api/addresses should create a new address', async () => {
    const res = await request(app)
      .post('/api/addresses')
      .set('Authorization', `Bearer ${clientToken}`)
      .send({
        label: 'Trabajo',
        addressLine: 'Av. Amazonas 456 y Colon',
        latitude: -0.1823,
        longitude: -78.4845,
        isDefault: true
      });
    expect(res.status).toBe(201);
    expect(res.body.address.label).toBe('Trabajo');
    expect(res.body.address.isDefault).toBe(true);

    addressId = res.body.address.id;
  });

  test('POST /api/addresses with isDefault should update old default address to false', async () => {
    // Add second default address
    const res = await request(app)
      .post('/api/addresses')
      .set('Authorization', `Bearer ${clientToken}`)
      .send({
        label: 'Casa',
        addressLine: 'Av. Shyris 789',
        latitude: -0.1750,
        longitude: -78.4800,
        isDefault: true
      });
    expect(res.status).toBe(201);
    expect(res.body.address.isDefault).toBe(true);

    // Verify first address is no longer default
    const getRes = await request(app)
      .get('/api/addresses')
      .set('Authorization', `Bearer ${clientToken}`);
    
    const firstAddr = getRes.body.addresses.find(a => a.id === addressId);
    expect(firstAddr.isDefault).toBe(false);
  });

  test('DELETE /api/addresses/:id should soft delete address', async () => {
    const res = await request(app)
      .delete(`/api/addresses/${addressId}`)
      .set('Authorization', `Bearer ${clientToken}`);
    expect(res.status).toBe(200);
    expect(res.body.message).toContain('Dirección eliminada');

    // Verify it is not returned in GET
    const getRes = await request(app)
      .get('/api/addresses')
      .set('Authorization', `Bearer ${clientToken}`);
    const ids = getRes.body.addresses.map(a => a.id);
    expect(ids).not.toContain(addressId);
  });

  test('DELETE /api/addresses/:id should return 404 for non-existent address', async () => {
    const randomUuid = require('crypto').randomUUID();
    const res = await request(app)
      .delete(`/api/addresses/${randomUuid}`)
      .set('Authorization', `Bearer ${clientToken}`);
    expect(res.status).toBe(404);
  });

  test('Addresses endpoints should handle db errors in catch block', async () => {
    const originalQuery = db.query;
    db.query = jest.fn().mockRejectedValue(new Error('DB failure'));

    let res = await request(app)
      .get('/api/addresses')
      .set('Authorization', `Bearer ${clientToken}`);
    expect(res.status).toBe(500);

    res = await request(app)
      .delete(`/api/addresses/${addressId}`)
      .set('Authorization', `Bearer ${clientToken}`);
    expect(res.status).toBe(500);

    db.query = originalQuery;

    const originalConnect = db.pool.connect;
    db.pool.connect = jest.fn().mockResolvedValue({
      query: jest.fn().mockImplementation((text, _params) => {
        if (text === 'BEGIN' || text === 'ROLLBACK' || text === 'COMMIT') {
          return Promise.resolve({ rowCount: 1, rows: [] });
        }
        return Promise.reject(new Error('Client query failure'));
      }),
      release: jest.fn()
    });

    res = await request(app)
      .post('/api/addresses')
      .set('Authorization', `Bearer ${clientToken}`)
      .send({
        label: 'Trabajo 2',
        addressLine: 'Av. Amazonas 456',
        latitude: -0.1823,
        longitude: -78.4845,
        isDefault: false
      });
    expect(res.status).toBe(500);

    db.pool.connect = originalConnect;
  });
});
