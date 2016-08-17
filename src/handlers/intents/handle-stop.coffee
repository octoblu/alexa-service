class HandleStop
  constructor: ({ @request, @response }) ->

  handle: (callback) =>
    @response.say "Closing session"
    @response.shouldEndSession true
    callback null

module.exports = HandleStop
