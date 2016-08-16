IntentHandler = require '../intent-handler'

class HandleIntentRequest
  constructor: ({ meshbluConfig, request, response }) ->
    @intentHandler = new IntentHandler {
      meshbluConfig,
      request,
      response
    }

  handle: (callback) =>
    @intentHandler.handle callback

module.exports = HandleIntentRequest
