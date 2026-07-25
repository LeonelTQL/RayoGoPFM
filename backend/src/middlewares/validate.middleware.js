function validate(schema) {
  return (req, res, next) => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      const errors = result.error.errors.map((error) => ({
        field: error.path.join('.'),
        message: error.message
      }));

      // Use the first error message as the main message for better UX
      const mainMessage = errors.length > 0 ? errors[0].message : 'Datos inválidos.';

      return res.status(400).json({
        message: mainMessage,
        errors
      });
    }
    req.body = result.data;
    return next();
  };
}

module.exports = { validate };
