class HandleCancel
  constructor: ({ @request, @response }) ->
    throw new Error 'Missing request' unless @request?
    throw new Error 'Missing response' unless @response?

  handle: (callback) =>
    @response.say "Closing session"
    @response.shouldEndSession true
    callback null

module.exports = HandleCancel
