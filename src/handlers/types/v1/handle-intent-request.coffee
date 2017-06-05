IntentHandler = require '../../intent-handler'

class HandleIntentRequest
  constructor: (options) ->
    {
      alexaServiceUri,
      sessionHandler,
      meshbluConfig,
      request,
      response,
      version,
    } = options
    throw new Error 'Missing alexaServiceUri' unless alexaServiceUri?
    throw new Error 'Missing request' unless request?
    throw new Error 'Missing response' unless response?
    throw new Error 'Missing sessionHandler' unless sessionHandler?
    throw new Error 'Missing version' unless version?
    @intentHandler = new IntentHandler {
      alexaServiceUri,
      sessionHandler,
      meshbluConfig,
      request,
      response,
      version,
    }

  handle: (callback) =>
    @intentHandler.handle callback

module.exports = HandleIntentRequest
