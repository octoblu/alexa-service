_      = require 'lodash'
Alexa  = require 'alexa-app'

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
      session = @_parse rawSession
      callback null, @_getResult { session, request }

  create: ({ session, request }, callback) =>
    key = "session:#{session.sessionId}"
    @client.set key, @_stringify(session), (error) =>
      return callback error if error?
      @client.expire key, @SESSION_TTL, (error) =>
        return callback error if error?
        callback null, @_getResult { session, request }

  leave: ({ shouldEndSession, sessionId }, callback) =>
    return callback null if shouldEndSession
    key = "session:#{sessionId}"
    @client.del key, callback

  respond: ({ response, responseId }, callback) =>
    key = "response:#{responseId}"
    @client.lpush key, @_stringify(response), (error) =>
      return callback error if error?
      @client.expire key, @RESPONSE_TTL, callback

  listen: ({ requestId }, callback) =>
    key = "response:#{requestId}"
    @client.brpop key, @RESPONSE_TTL, (error, result) =>
      delete error.code if error?
      return callback error if error?
      unless result?
        error = new Error 'Response timeout exceeded'
        error.code = 504
        return callback error
      [ channel, rawResponse ] = result
      callback null, @_parse rawResponse

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
