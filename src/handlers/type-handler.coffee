_           = require 'lodash'
Types       = require './types'
AlexaConfig = require '../models/alexa-meshblu-config'

class TypeHandler
  constructor: ({ meshbluConfig, request, response }) ->
    @type = request.type()
    meshbluConfig = new AlexaConfig({ meshbluConfig, request }).get()
    @options = {
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
