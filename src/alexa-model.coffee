request         = require 'request'

DEBUG_RESPONSE  = {
  "version": "1.0",
  "response": {
    "outputSpeech": {
      "type": "PlainText",
      "text": "It has been done!"
    },
    "shouldEndSession": true
  }
}

class AlexaModel
  debug: (json, callback=->) =>
    request.post 'http://requestb.in/1gy5wgo1', json: json, (error) =>
      return callback error if error?
      callback null, DEBUG_RESPONSE

  trigger: (alexaIntent, callback=->) =>
    callback null, DEBUG_RESPONSE

module.exports = AlexaModel
