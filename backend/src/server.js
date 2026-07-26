require('dotenv').config();
const http = require('node:http');
const app = require('./app');
const { initSocket } = require('./config/socket');

const PORT = process.env.PORT || 4000;
const server = http.createServer(app);

// Initialize Socket.io
initSocket(server);

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Smart Delivery API & Real-time Server running on http://localhost:${PORT}`);
});
