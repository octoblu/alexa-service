Alexa = require 'alexa-app'

class AlexaError
  constructor: (@message, shouldEndSession=true) ->
    response = new Alexa.response()
    response.say @message
    response.shouldEndSession shouldEndSession
    @response = response.response

module.exports = AlexaError
