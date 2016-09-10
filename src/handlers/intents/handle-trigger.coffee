_                    = require 'lodash'
AuthenticatedHandler = require '../authenticated-handler'
EchoInService        = require '../../services/echo-in-service'
debug                = require('debug')('alexa-service:handle-trigger')

class HandleTrigger
  constructor: ({ @alexaServiceUri, @sessionHandler, @meshbluConfig, @request, @response }) ->
    throw new Error 'Missing sessionHandler' unless @sessionHandler?
    throw new Error 'Missing alexaServiceUri' unless @alexaServiceUri?
    throw new Error 'Missing request' unless @request?
    throw new Error 'Missing response' unless @response?
    { @sessionId } = @request.sessionDetails
    @authenticatedHandler = new AuthenticatedHandler { @meshbluConfig, @request, @response }

  handle: (callback) =>
    debug 'handling trigger'
    @authenticatedHandler.handle callback, =>
      @echoInService = new EchoInService { @meshbluConfig }
      @_trigger callback, =>
        @_waitForResponse callback

  _waitForResponse: (callback) =>
    { requestId } = @request.data.request
    debug 'waiting for response', { requestId }
    @sessionHandler.listen { requestId }, (error, result) =>
      debug 'got job response', { error, result }
      return @_requestTimeout callback if error?.code == 504
      return callback error if error?
      @_convertResultToResponse result
      debug 'calling it done'
      callback null

  _convertLegacyResult: (result={}) =>
    { responseText } = result
    @response.say responseText
    @response.shouldEndSession true

  _convertJobResult: (data) =>
    @response.response = _.assign @response, data

  _convertResultToResponse: (data={}) =>
    return @_convertLegacyResult data if data.responseText?
    return @_convertJobResult data

  _intentName: =>
    return @request.data?.request?.intent?.name

  _trigger: (callback, next) =>
    return @_triggerLast callback, next unless @_intentName() == 'Trigger'
    name = @request.slot 'Name'
    return @_invalidRequest callback unless name
    { requestId } = @request.data.request
    debug 'triggering', { name, requestId }
    @echoInService.list (error, list) =>
      return callback error if error?
      echoIn = list.findByName name
      return @_missingEchoIn callback unless echoIn?
      @sessionHandler.saveEchoIn { @sessionId, echoIn }, (error) =>
        return callback error if error?
        debug 'got echo-in', echoIn.name()
        options = { @sessionId, responseId: requestId, baseUrl: @alexaServiceUri }
        message = echoIn.buildMessage options, @request.data.request
        debug 'sending message', { message }
        @echoInService.message message, (error) =>
          return callback error if error?
          debug 'sent message'
          next null

  _triggerLast: (callback, next) =>
    { requestId } = @request.data.request
    debug 'triggering last', { requestId }
    @sessionHandler.getEchoIn { @sessionId }, (error, echoIn) =>
      return callback error if error?
      return @_invalidRequest callback unless echoIn?
      debug 'got last echo-in', echoIn.name()
      options = { @sessionId, responseId: requestId, baseUrl: @alexaServiceUri }
      message = echoIn.buildMessage options, @request.data.request
      debug 'sending message to last echo-in', { message }
      @echoInService.message message, (error) =>
        return callback error if error?
        debug 'sent message to last echo-in'
        next null

  _invalidRequest: (callback) =>
    debug 'invalid request'
    @response.say "Invalid request"
    @response.shouldEndSession true
    callback null

  _requestTimeout: (callback) =>
    debug 'request timeout'
    @response.say "Response timeout exceeded"
    @response.shouldEndSession true
    callback null

  _missingEchoIn: (callback) =>
    debug 'missing echo in'
    @response.say "No echo-in by that name"
    @response.shouldEndSession false, "Please say the name of a echo-in associated with your account"
    callback null

module.exports = HandleTrigger
