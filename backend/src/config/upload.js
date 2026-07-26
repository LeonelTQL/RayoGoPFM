const path = require('node:path');
const fs = require('node:fs');
const multer = require('multer');

const uploadDir = process.env.UPLOAD_DIR || 'uploads';
const fullPath = path.join(__dirname, '..', '..', uploadDir);

if (!fs.existsSync(fullPath)) {
  fs.mkdirSync(fullPath, { recursive: true });
}

const crypto = require('node:crypto');

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, fullPath),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname || '.jpg');
    cb(null, `${Date.now()}-${crypto.randomBytes(4).toString('hex')}${ext}`);
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const isImageMime = file.mimetype.startsWith('image/');
    const ext = path.extname(file.originalname || '').toLowerCase();
    const allowedExts = ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.heic', '.heif'];
    const isImageExt = allowedExts.includes(ext);
    
    if (isImageMime || isImageExt || file.mimetype === 'application/octet-stream') {
      return cb(null, true);
    }
    return cb(new Error('Solo se permiten imágenes.'));
  }
});

function buildFileUrl(req, filename) {
  const base = process.env.PUBLIC_BASE_URL || `${req.protocol}://${req.get('host')}`;
  return `${base}/uploads/${filename}`;
}

module.exports = { upload, buildFileUrl };
