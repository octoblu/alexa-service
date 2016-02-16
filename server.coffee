express         = require 'express'
bodyParser      = require 'body-parser'
morgan          = require 'morgan'
errorhandler    = require 'errorhandler'
MeshbluConfig   = require 'meshblu-config'
healthcheck     = require 'express-meshblu-healthcheck'
AlexaController = require './src/alexa-controller'

app = express()
app.use bodyParser.json()
app.use morgan 'dev'
app.use errorhandler()
app.use healthcheck()

meshbluConfig = new MeshbluConfig({}).toJSON()

restServiceUri = process.env.REST_SERVICE_URI || 'https://rest.octoblu.com'
alexaController = new AlexaController {meshbluConfig,restServiceUri}

app.post '/debug', alexaController.debug

app.post '/trigger', alexaController.trigger

app.post '/respond/:responseId', alexaController.respond

server = app.listen (process.env.ALEXA_PORT || 80), ->
  host = server.address().address
  port = server.address().port

  console.log "Alexa Service started http://#{host}:#{port}"
