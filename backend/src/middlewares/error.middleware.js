function errorHandler(error, req, res, _next) {
  console.error(error);
  const status = error.status || 500;
  
  let message = error.message;
  if (status === 500 || error.code || error.severity || error.routine) {
    message = 'Ha ocurrido un error en el servidor. Por favor, inténtelo de nuevo más tarde.';
  }

  return res.status(status).json({
    message: message || 'Error interno del servidor.'
  });
}

module.exports = { errorHandler };
