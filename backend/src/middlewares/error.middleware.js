function errorHandler(error, req, res, next) {
  console.error(error);
  const status = error.status || 500;
  return res.status(status).json({
    message: error.message || 'Error interno del servidor.'
  });
}

module.exports = { errorHandler };
