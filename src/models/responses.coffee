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

responses.CARD_RESPONSE =
  version: "1.0"
  response:
    outputSpeech:
      type: "PlainText"
      text: "Response"
    card:
      type: "Simple",
      title: "Example of the Card Title",
      content: "Example of card content. This card has just plain text content.\nThe content is formatted with line breaks to improve readability."

responses.LINK_ACCOUNT_CARD_RESPONSE =
  version: "1.0"
  response:
    outputSpeech:
      type: "PlainText"
      text: "Please go to your Alexa app and link your account."
    card:
      type: "LinkAccount"

module.exports = responses
