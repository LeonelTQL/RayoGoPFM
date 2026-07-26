const { signUserToken } = require('../src/utils/token');
const jwt = require('jsonwebtoken');

describe('Token Utility', () => {
  test('signs a token with user data', () => {
    const user = { id: '123', email: 'test@example.com', name: 'Test', role: 'cliente' };
    const token = signUserToken(user);
    expect(token).toBeDefined();

    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'dev_secret');
    expect(decoded.id).toBe(user.id);
    expect(decoded.email).toBe(user.email);
    expect(decoded.name).toBe(user.name);
    expect(decoded.role).toBe(user.role);
  });
});
