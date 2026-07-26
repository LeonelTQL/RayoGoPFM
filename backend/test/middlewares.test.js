process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test_secret_longer_than_32_characters_for_signing_tokens';

const express = require('express');
const request = require('supertest');
const { requireAuth } = require('../src/middlewares/auth.middleware');
const { allowRoles } = require('../src/middlewares/role.middleware');
const { errorHandler } = require('../src/middlewares/error.middleware');
const { validate } = require('../src/middlewares/validate.middleware');
const { z } = require('zod');
const jwt = require('jsonwebtoken');

describe('Middlewares', () => {
  test('validate middleware allows valid body', async () => {
    const schema = z.object({ name: z.string() });
    const app = express();
    app.use(express.json());
    app.post('/test', validate(schema), (req, res) => res.json(req.body));

    const response = await request(app).post('/test').send({ name: 'Leonel' });
    expect(response.status).toBe(200);
    expect(response.body.name).toBe('Leonel');
  });

  test('validate middleware rejects invalid body', async () => {
    const schema = z.object({ name: z.string().min(3) });
    const app = express();
    app.use(express.json());
    app.post('/test', validate(schema), (req, res) => res.json(req.body));

    const response = await request(app).post('/test').send({ name: 'Le' });
    expect(response.status).toBe(400);
    expect(response.body).toHaveProperty('errors');
  });

  test('allowRoles allows users with correct roles', () => {
    const middleware = allowRoles('admin');
    const req = { user: { role: 'admin' } };
    const res = {};
    const next = jest.fn();
    middleware(req, res, next);
    expect(next).toHaveBeenCalled();
  });

  test('allowRoles rejects users with incorrect roles', async () => {
    const middleware = allowRoles('admin');
    const req = { user: { role: 'cliente' } };
    const res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn()
    };
    const next = jest.fn();
    middleware(req, res, next);
    expect(res.status).toHaveBeenCalledWith(403);
    expect(next).not.toHaveBeenCalled();
  });

  test('requireAuth rejects requests without token', async () => {
    const app = express();
    app.get('/protected', requireAuth, (req, res) => res.json(req.user));
    const response = await request(app).get('/protected');
    expect(response.status).toBe(401);
  });

  test('requireAuth rejects requests with invalid token', async () => {
    const app = express();
    app.get('/protected', requireAuth, (req, res) => res.json(req.user));
    const response = await request(app).get('/protected').set('Authorization', 'Bearer invalid_token');
    expect(response.status).toBe(401);
  });

  test('requireAuth accepts valid token', async () => {
    const app = express();
    app.get('/protected', requireAuth, (req, res) => res.json(req.user));
    const token = jwt.sign({ id: '123', role: 'admin' }, process.env.JWT_SECRET || 'dev_secret');
    const response = await request(app).get('/protected').set('Authorization', `Bearer ${token}`);
    expect(response.status).toBe(200);
    expect(response.body.id).toBe('123');
  });

  test('requireAuth rejects expired token', async () => {
    const app = express();
    app.get('/protected', requireAuth, (req, res) => res.json(req.user));
    const token = jwt.sign({ id: '123', role: 'admin' }, process.env.JWT_SECRET || 'dev_secret', { expiresIn: '-1s' });
    const response = await request(app).get('/protected').set('Authorization', `Bearer ${token}`);
    expect(response.status).toBe(401);
    expect(response.body.message).toContain('caducado');
  });

  test('errorHandler formats server errors', () => {
    const error = new Error('Database connection failed');
    error.code = '57P01';
    const req = {};
    const res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn()
    };
    const next = jest.fn();
    errorHandler(error, req, res, next);
    expect(res.status).toHaveBeenCalledWith(500);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        message: expect.stringContaining('error en el servidor')
      })
    );
  });
});
