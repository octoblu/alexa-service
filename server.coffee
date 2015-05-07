express = require 'express'
bodyParser = require 'body-parser'
morgan = require 'morgan'
errorhandler  = require 'errorhandler'
request = require 'request'

app = express()
app.use bodyParser()
app.use morgan()
app.use errorhandler()

RESPONSE = {
  "version": "1.0",
  "response": {
    "outputSpeech": {
      "type": "PlainText",
      "text": "Happy birthday Jade"
    },
    "shouldEndSession": true
  }
}

app.post '/debug', (req, res) ->
  json = {body: req.body, headers: req.headers}
  request.post 'http://requestb.in/ukminwuk', json: json, =>
    res.status(200).send(RESPONSE)

server = app.listen (process.env.ALEXA_SERVICE_PORT || 80), ->
  host = server.address().address
  port = server.address().port

  console.log 'Example app listening at http://%s:%s', host, port
