Success = (res, message, data = null, status = 200, meta = null) => {
  return res.status(status).json({
    success: true,
    message,
    data,
    ...(meta ? { meta } : {})
  });
};

ErrorResponse = (res, message, errors = null, status = 400) => {
  console.error(`\n❌ [ERROR RESPONSE] ${status} - ${message}`);
  if (errors) {
    console.error('📝 Details:', errors);
  }
  
  return res.status(status).json({
    success: false,
    message,
    errors
  });
};
module.exports = {
    Success,
    ErrorResponse
}