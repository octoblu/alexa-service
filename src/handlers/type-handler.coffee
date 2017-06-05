Types       = require './types'
AlexaConfig = require '../models/alexa-meshblu-config'

class TypeHandler
  constructor: (options) ->
    {
      alexaServiceUri,
      sessionHandler,
      meshbluConfig,
      request,
      response,
      @version,
    } = options
    throw new Error 'Missing alexaServiceUri' unless alexaServiceUri?
    throw new Error 'Missing sessionHandler' unless sessionHandler?
    throw new Error 'Missing meshbluConfig' unless meshbluConfig?
    throw new Error 'Missing request' unless request?
    throw new Error 'Missing response' unless response?
    throw new Error 'Missing version' unless @version?
    @type  = request.type()
    meshbluConfig = new AlexaConfig({ meshbluConfig, request }).get()
    @options = {
      alexaServiceUri,
      sessionHandler,
      meshbluConfig,
      request,
      response,
      @version,
    }

  handle: (callback) =>
    return @_invalidType callback unless Types[@version][@type]?
    @typeHandler = new Types[@version][@type] @options
    @typeHandler.handle callback

  _invalidType: (callback) =>
    callback new Error "Error: not a valid request"

module.exports = TypeHandler
