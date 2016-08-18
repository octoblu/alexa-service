_           = require 'lodash'
Types       = require './types'
AlexaConfig = require '../models/alexa-meshblu-config'

class TypeHandler
  constructor: ({ alexaServiceUri, jobManager, meshbluConfig, request, response }) ->
    throw new Error 'Missing alexaServiceUri' unless alexaServiceUri?
    throw new Error 'Missing jobManager' unless jobManager?
    throw new Error 'Missing meshbluConfig' unless meshbluConfig?
    throw new Error 'Missing request' unless request?
    throw new Error 'Missing response' unless response?
    @type = request.type()
    meshbluConfig = new AlexaConfig({ meshbluConfig, request }).get()
    @options = {
      alexaServiceUri,
      jobManager,
      meshbluConfig,
      request,
      response
    }

  handle: (callback) =>
    return @_invalidType callback unless Types[@type]?
    @typeHandler = new Types[@type] @options
    @typeHandler.handle callback

  _invalidType: (callback) =>
    callback new Error "Error: not a valid request"

module.exports = TypeHandler
