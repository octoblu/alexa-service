_                    = require 'lodash'
AuthenticatedHandler = require '../authenticated-handler'
EchoInService        = require '../../services/echo-in-service'
debug                = require('debug')('alexa-service:handle-trigger')

class HandleTrigger
  constructor: ({ @alexaServiceUri, @jobManager, @meshbluConfig, @request, @response }) ->
    throw new Error 'Missing jobManager' unless @jobManager?
    throw new Error 'Missing alexaServiceUri' unless @alexaServiceUri?
    throw new Error 'Missing request' unless @request?
    throw new Error 'Missing response' unless @response?
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
    @jobManager.getResponse 'response', requestId, (error, result) =>
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

  _parseJobResult: (result={}) =>
    try
      data = JSON.parse result.rawData
    catch error
      throw error if error?
    return data

  _convertJobResult: () =>
    { response } = data
    @response.response = response

  _convertResultToResponse: (result={}) =>
    data = @_parseJobResult result
    return @_convertLegacyResult data if data.responseText?
    return @_convertJobResult data

  _trigger: (callback, next) =>
    name = @request.slot 'Name'
    return @_invalidName callback unless name
    { requestId } = @request.data.request
    debug 'triggering', { name, requestId }
    @echoInService.list (error, list) =>
      return callback error if error?
      echoIn = list.findByName name
      return @_missingEchoIn callback unless echoIn?
      debug 'got echo-in', echoIn.name()
      options = { responseId: requestId, baseUrl: @alexaServiceUri }
      message = echoIn.buildMessage options, @request.data.request
      debug 'sending message', { message }
      @echoInService.message message, (error) =>
        return callback error if error?
        debug 'sent message'
        next null

  _invalidName: (callback) =>
    debug 'invalid name'
    @response.say "Missing Name slot for Trigger intent"
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
