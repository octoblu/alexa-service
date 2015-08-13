express         = require 'express'
bodyParser      = require 'body-parser'
morgan          = require 'morgan'
errorhandler    = require 'errorhandler'
healthcheck     = require 'express-meshblu-healthcheck'
AlexaController = require './src/alexa-controller'

app = express()
app.use bodyParser.json()
app.use morgan 'dev'
app.use errorhandler()
app.use healthcheck()

alexaController = new AlexaController

app.post '/debug', alexaController.debug

app.post '/trigger', alexaController.trigger

app.post '/respond', alexaController.respond

server = app.listen (process.env.ALEXA_SERVICE_PORT || 80), ->
  host = server.address().address
  port = server.address().port

  console.log "Alexa Service started http://#{host}:#{port}"
