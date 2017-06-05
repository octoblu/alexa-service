_                    = require 'lodash'
AuthenticatedHandler = require '../../authenticated-handler'
EchoDeviceService    = require '../../../services/echo-device-service'
AlexaError           = require '../../../models/alexa-error'
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
      @echoDeviceService = new EchoDeviceService { @meshbluConfig }
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
    @response.response = _.assign @response.response, data

  _convertResultToResponse: (data={}) =>
    return @_convertLegacyResult data if data.responseText?
    return @_convertJobResult data

  _intentName: =>
    return @request.data?.request?.intent?.name

  _trigger: (callback, next) =>
    return @_triggerLast callback, next unless @_intentName() == 'Trigger'
    name = @request.slot 'Name'
    return callback new AlexaError 'Invalid trigger request' unless name
    { requestId } = @request.data.request
    debug 'triggering', { name, requestId }
    @echoDeviceService.get (error, echoDevice) =>
      return callback error if error?
      @sessionHandler.saveEchoDevice { @sessionId, echoDevice }, (error) =>
        return callback error if error?
        options = {
          @sessionId,
          responseId: requestId,
          baseUrl: @alexaServiceUri
          type: 'new'
        }
        message = echoDevice.buildMessage options, @request.data.request
        @echoDeviceService.message message, (error) =>
          return callback error if error?
          next()

  _triggerLast: (callback, next) =>
    { requestId } = @request.data.request
    debug 'triggering last', { requestId }
    @sessionHandler.getEchoDevice { @sessionId }, (error, echoDevice) =>
      return callback error if error?
      return callback new AlexaError 'No trigger to reply to' unless echoDevice?
      options = {
        @sessionId,
        responseId: requestId,
        baseUrl: @alexaServiceUri
        type: 'reply'
      }
      message = echoDevice.buildMessage options, @request.data.request
      @echoDeviceService.message message, (error) =>
        return callback error if error?
        next()

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

module.exports = HandleTrigger
