_       = require 'lodash'
debug   = require('debug')('alexa-service:intent-handler')
Intents = require './intents'

class IntentHandler
  constructor: (options) ->
    {
      alexaServiceUri,
      sessionHandler,
      meshbluConfig,
      request,
      @response,
      @version,
    } = options
    throw new Error 'Missing alexaServiceUri' unless alexaServiceUri?
    throw new Error 'Missing sessionHandler' unless sessionHandler?
    throw new Error 'Missing request' unless request?
    throw new Error 'Missing response' unless @response?
    throw new Error 'Missing version' unless @version?
    @intentName = _.get request, 'data.request.intent.name'
    @intentName = 'default' unless Intents[@version][@intentName]?
    @intentName ?= 'default'
    debug 'received intent', { @intentName }
    @options = {
      alexaServiceUri,
      sessionHandler,
      meshbluConfig,
      request,
      @response,
      @version,
    }

  handle: (callback) =>
    @intent = new Intents[@version][@intentName] @options
    @intent.handle callback

  _invalidIntent: (callback) =>
    debug "invalid intent: #{@version}:#{@intentName}"
    message = "Sorry, the application didn't know what to do with that intent."
    @response.say message
    @response.shouldEndSession true, "Please say the name of a trigger associated with your account"
    callback null

module.exports = IntentHandler
