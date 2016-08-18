IntentHandler = require '../intent-handler'

class HandleIntentRequest
  constructor: ({ alexaServiceUri, jobManager, meshbluConfig, request, response }) ->
    throw new Error 'Missing alexaServiceUri' unless alexaServiceUri?
    throw new Error 'Missing meshbluConfig' unless meshbluConfig?
    throw new Error 'Missing request' unless request?
    throw new Error 'Missing response' unless response?
    throw new Error 'Missing jobManager' unless jobManager?
    @intentHandler = new IntentHandler {
      alexaServiceUri,
      jobManager,
      meshbluConfig,
      request,
      response
    }

  handle: (callback) =>
    @intentHandler.handle callback

module.exports = HandleIntentRequest
