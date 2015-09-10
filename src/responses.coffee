responses = {}
responses.DEBUG_RESPONSE  =
  version: "1.0"
  response:
    outputSpeech:
      type: "PlainText"
      text: "It has been done!"
    shouldEndSession: true

responses.OPEN_RESPONSE  =
  version: "1.0"
  response:
    outputSpeech:
      type: "PlainText"
      text: "What would you like to do?"
    shouldEndSession: false

responses.CLOSE_RESPONSE  =
  version: "1.0"
  response:
    outputSpeech:
      type: "PlainText"
      text: "Session Closed"
    shouldEndSession: true

responses.SUCCESS_RESPONSE  =
  version: "1.0"
  response:
    outputSpeech:
      type: "PlainText"
      text: "Success"
    shouldEndSession: true

module.exports = responses
