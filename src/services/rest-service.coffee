request = require 'request'
SimpleBenchmark = require 'simple-benchmark'
debug           = require('debug')('alexa-service:rest-service')

class RestService
  constructor: ({@meshbluConfig,@restServiceUri}) ->
  trigger: (name, body, callback) =>
    options =
      baseUrl: @restServiceUri
      uri: "/flows/triggers/#{name}"
      auth:
        username: @meshbluConfig.uuid
        password: @meshbluConfig.token
      headers:
        'X-RESPONSE-BASE-URI': 'https://alexa.octoblu.com'
      json: body
      timeout: 9 * 1000

    request.post options, (error, response, body)=>
      return callback new Error 'Request Timeout' if error?.code == 'ETIMEDOUT'
      return callback error if error?
      callback null, code: response.statusCode, data: body

  respond: (responseId, body, callback) =>
    options =
      baseUrl: @restServiceUri
      uri: "/respond/#{responseId}"
      json: body

    benchmark = new SimpleBenchmark
    request.post options, (error, response, body)=>
      debug 'respond benchmark', benchmark.toString()
      return callback error if error?
      callback null, code: response.statusCode, data: body

module.exports = RestService
