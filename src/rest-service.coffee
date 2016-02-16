request = require 'request'

class RestService
  constructor: ({@meshbluConfig,@restServiceUri}) ->
  trigger: (name, body, callback) =>
    options =
      baseUrl: @restServiceUri
      uri: "/flows/triggers/#{name}"
      auth:
        username: @meshbluConfig.uuid
        password: @meshbluConfig.token
      json: body

    request.post options, (error, response, body)=>
      return callback error if error?
      callback null, code: response.statusCode, data: body

  respond: (repsonseId, body, callback) =>
    options =
      baseUrl: @restServiceUri
      uri: "/respond/#{responseId}"
      auth:
        username: @meshbluConfig.uuid
        password: @meshbluConfig.token
      json: body

    request.post options, (error, response, body)=>
      return callback error if error?
      callback null, code: response.statusCode, data: body

module.exports = RestService
