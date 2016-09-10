IntentHandler = require '../intent-handler'

class HandleIntentRequest
  constructor: ({ alexaServiceUri, sessionHandler, meshbluConfig, request, response }) ->
    throw new Error 'Missing alexaServiceUri' unless alexaServiceUri?
    throw new Error 'Missing request' unless request?
    throw new Error 'Missing response' unless response?
    throw new Error 'Missing sessionHandler' unless sessionHandler?
    @intentHandler = new IntentHandler {
      alexaServiceUri,
      sessionHandler,
      meshbluConfig,
      request,
      response
    }

  handle: (callback) =>
    @intentHandler.handle callback

module.exports = HandleIntentRequest
