const { Router } = require('express');
const { requireAuth } = require('../../middlewares/auth.middleware');
const { upload, buildFileUrl } = require('../../config/upload');

const router = Router();

router.post('/image', requireAuth, upload.single('image'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ message: 'La imagen es obligatoria.' });
  }
  return res.status(201).json({ imageUrl: buildFileUrl(req, req.file.filename) });
});

module.exports = router;
