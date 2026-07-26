process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test_secret_longer_than_32_characters_for_signing_tokens';

const request = require('supertest');
const app = require('../src/app');
const db = require('../src/config/db');
const { signUserToken } = require('../src/utils/token');

beforeAll(async () => {
  await db.initializeTestDb();
});

describe('Products Endpoints', () => {
  let clientToken;
  let adminToken;
  let createdProductId;

  beforeAll(() => {
    clientToken = signUserToken({ id: 'client-123', email: 'client@example.com', name: 'Client', role: 'cliente' });
    adminToken = signUserToken({ id: 'admin-123', email: 'admin@example.com', name: 'Admin', role: 'admin' });
  });

  test('GET /api/products should return list of active products', async () => {
    const res = await request(app).get('/api/products');
    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('products');
    expect(Array.isArray(res.body.products)).toBe(true);
  });

  test('POST /api/products should fail if user is not admin', async () => {
    const res = await request(app)
      .post('/api/products')
      .set('Authorization', `Bearer ${clientToken}`)
      .send({
        name: 'Burger Classic',
        price: 5.99,
        stock: 50
      });
    expect(res.status).toBe(403);
  });

  test('POST /api/products should succeed if user is admin', async () => {
    const res = await request(app)
      .post('/api/products')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        name: 'Burger Classic',
        price: 5.99,
        stock: 50,
        description: 'Deliciosa hamburguesa clasica',
        imageUrl: 'http://image.url/burger.png',
        originalPrice: 8.99,
        discountPercent: 10
      });
    expect(res.status).toBe(201);
    expect(res.body.product.name).toBe('Burger Classic');
    expect(res.body.product.price).toBe(5.99);
    expect(res.body.product.originalPrice).toBe(8.99);
    expect(res.body.product.discountPercent).toBe(10);
    
    createdProductId = res.body.product.id;
  });

  test('GET /api/products with search parameter should return matching products', async () => {
    const res = await request(app).get('/api/products?search=Burger');
    expect(res.status).toBe(200);
    expect(res.body.products.length).toBeGreaterThan(0);
  });

  test('GET /api/products/:id should return single product details', async () => {
    const res = await request(app).get(`/api/products/${createdProductId}`);
    expect(res.status).toBe(200);
    expect(res.body.product.id).toBe(createdProductId);
  });

  test('GET /api/products/:id should return 404 for non-existent product', async () => {
    const randomUuid = require('crypto').randomUUID();
    const res = await request(app).get(`/api/products/${randomUuid}`);
    expect(res.status).toBe(404);
  });

  test('PUT /api/products/:id should update product details partially', async () => {
    const res = await request(app)
      .put(`/api/products/${createdProductId}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        name: 'Burger Special',
        price: 6.99
      });
    expect(res.status).toBe(200);
    expect(res.body.product.name).toBe('Burger Special');
    expect(res.body.product.price).toBe(6.99);
  });

  test('PUT /api/products/:id should return 404 for non-existent product', async () => {
    const randomUuid = require('crypto').randomUUID();
    const res = await request(app)
      .put(`/api/products/${randomUuid}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ name: 'Burger Special', price: 6.99, stock: 10 });
    expect(res.status).toBe(404);
  });

  test('DELETE /api/products/:id should deactivate product', async () => {
    const res = await request(app)
      .delete(`/api/products/${createdProductId}`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(200);
    expect(res.body.message).toContain('Producto desactivado');

    // Confirm it is not returned in listing
    const listRes = await request(app).get('/api/products');
    const ids = listRes.body.products.map(p => p.id);
    expect(ids).not.toContain(createdProductId);
  });

  test('DELETE /api/products/:id should return 404 for non-existent product', async () => {
    const randomUuid = require('crypto').randomUUID();
    const res = await request(app)
      .delete(`/api/products/${randomUuid}`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(404);
  });

  test('Products endpoints should handle db errors in catch block', async () => {
    const originalQuery = db.query;
    db.query = jest.fn().mockRejectedValue(new Error('DB failure'));

    let res = await request(app).get('/api/products');
    expect(res.status).toBe(500);

    res = await request(app).get(`/api/products/${createdProductId}`);
    expect(res.status).toBe(500);

    res = await request(app)
      .post('/api/products')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ name: 'Burger Classic', price: 5.99, stock: 50 });
    expect(res.status).toBe(500);

    res = await request(app)
      .put(`/api/products/${createdProductId}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ name: 'Burger Special', price: 6.99 });
    expect(res.status).toBe(500);

    res = await request(app)
      .delete(`/api/products/${createdProductId}`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(500);

    db.query = originalQuery;
  });
});
