_          = require 'lodash'
Alexa      = require 'alexa-app'
EchoIn     = require '../models/echo-in'
AlexaError = require '../models/alexa-error'

class SessionHandler
  constructor: ({ timeoutSeconds, @client }) ->
    throw new Error 'Missing client' unless @client?
    if timeoutSeconds
      @SESSION_TTL  = timeoutSeconds * 2
      @RESPONSE_TTL = timeoutSeconds
    else
      @SESSION_TTL  = 60 * 60
      @RESPONSE_TTL = 10

  start: ({ session, request }, callback) =>
    return @create { session, request }, callback if session.new
    @join { session, request }, callback

  join: ({ session, request }, callback) =>
    key = "session:#{session.sessionId}"
    @client.get key, (error, rawSession) =>
      return callback error if error?
      return callback new AlexaError 'Unable to find session' unless rawSession?
      session = @_parse rawSession
      callback null, @_getResult { session, request }
    return # redis fix

  create: ({ session, request }, callback) =>
    key = "session:#{session.sessionId}"
    @client.set key, @_stringify(session), (error) =>
      return callback error if error?
      @client.expire key, @SESSION_TTL, (error) =>
        return callback error if error?
        callback null, @_getResult { session, request }
    return # redis fix

  leave: ({ shouldEndSession, sessionId }, callback) =>
    return callback null if shouldEndSession
    @client.del "session:#{sessionId}", (error) =>
      return callback error if error?
      @client.del "session:#{sessionId}:echo-in", callback
    return # redis fix

  respond: ({ body, responseId }, callback) =>
    key = "response:#{responseId}"
    @client.lpush key, @_stringify(body), (error) =>
      return callback error if error?
      @client.expire key, @RESPONSE_TTL, callback
    return # redis fix

  listen: ({ requestId }, callback) =>
    key = "response:#{requestId}"
    @client.brpop key, @RESPONSE_TTL, (error, result) =>
      return callback error if error?
      unless result?
        error = new Error 'Response timeout exceeded'
        error.code = 504
        return callback error
      [ channel, rawResponse ] = result
      callback null, @_parse rawResponse
    return # redis fix

  getEchoIn: ({ sessionId }, callback) =>
    key = "session:#{sessionId}:echo-in"
    @client.get key, (error, rawEchoIn) =>
      return callback error if error?
      return callback null unless rawEchoIn?
      echoIn = new EchoIn()
      echoIn.fromJSON rawEchoIn
      callback null, echoIn
    return # redis fix

  saveEchoIn: ({ sessionId, echoIn }, callback) =>
    key = "session:#{sessionId}:echo-in"
    @client.set key, echoIn.toJSON(), (error) =>
      return callback error if error?
      @client.expire key, @SESSION_TTL, callback
    return # redis fix

  _stringify: (obj) =>
    return JSON.stringify obj

  _parse: (str) =>
    return JSON.parse str

  _getResult: ({ session, request }) =>
    session ?= {}
    session.user ?= {}
    session.application ?= {}
    body = { session, request }
    request = new Alexa.request body
    response = new Alexa.response()
    _.each _.keys(request.sessionAttributes), (key) =>
      response.session key, request.sessionAttributes[key]
    return { request, response }

module.exports = SessionHandler
