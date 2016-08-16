class HandleStop
  constructor: ({ @request, @response }) ->

  handle: (callback) =>
    @response.clear()
    @response.shouldEndSession true
    callback null

module.exports = HandleStop
