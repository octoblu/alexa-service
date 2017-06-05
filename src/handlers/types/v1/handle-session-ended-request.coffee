class HandleEndSessionRequest
  constructor: ({ @response }) ->
    throw new Error 'Missing response' unless @response?

  handle: (callback) =>
    @response.clear()
    @response.shouldEndSession true
    callback null

module.exports = HandleEndSessionRequest
