class HandleEndSessionRequest
  constructor: ({ @response }) ->

  handle: (callback) =>
    @response.clear()
    @response.shouldEndSession true
    callback null

module.exports = HandleEndSessionRequest
