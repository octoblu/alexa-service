responses = {}
responses.CLOSE_RESPONSE  =
  version: "1.0"
  response:
    outputSpeech:
      type: "PlainText"
      text: "Closing session"
    shouldEndSession: true

responses.SUCCESS_RESPONSE  =
  version: "1.0"
  response:
    outputSpeech:
      type: "PlainText"
      text: "Success"
    shouldEndSession: true

module.exports = responses
