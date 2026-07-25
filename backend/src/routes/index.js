const { Router } = require('express');
const authRoutes = require('../modules/auth/auth.routes');
const categoryRoutes = require('../modules/categories/categories.routes');
const productRoutes = require('../modules/products/products.routes');
const addressRoutes = require('../modules/addresses/addresses.routes');
const orderRoutes = require('../modules/orders/orders.routes');
const deliveryRoutes = require('../modules/delivery/delivery.routes');
const paymentRoutes = require('../modules/payments/payments.routes');
const uploadRoutes = require('../modules/uploads/uploads.routes');
const notificationRoutes = require('../modules/notifications/notifications.routes');
const mapsRoutes = require('../modules/maps/maps.routes');

const router = Router();

router.use('/auth', authRoutes);
router.use('/categories', categoryRoutes);
router.use('/products', productRoutes);
router.use('/addresses', addressRoutes);
router.use('/orders', orderRoutes);
router.use('/delivery', deliveryRoutes);
router.use('/payments', paymentRoutes);
router.use('/uploads', uploadRoutes);
router.use('/notifications', notificationRoutes);
router.use('/maps', mapsRoutes);

module.exports = router;
