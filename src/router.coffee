passport           = require 'passport'
AlexaController    = require './controllers/alexa-controller'
V2AlexaController  = require './controllers/v2-alexa-controller'
SchemasController   = require './controllers/schemas-controller'

class Router
  constructor: ({timeoutSeconds,meshbluConfig, alexaServiceUri}) ->
    throw new Error 'Missing meshbluConfig' unless meshbluConfig?
    throw new Error 'Missing alexaServiceUri' unless alexaServiceUri?
    @alexaController = new AlexaController {timeoutSeconds,meshbluConfig, alexaServiceUri}
    @v2AlexaController = new V2AlexaController {timeoutSeconds,meshbluConfig, alexaServiceUri}
    @schemasController = new SchemasController {}

  route: (app) =>
    app.post '/trigger', @alexaController.trigger
    app.post '/respond/:responseId', @alexaController.respond

    app.post '/v2/trigger', @v2AlexaController.trigger
    app.post '/v2/respond', @v2AlexaController.respond

    app.get '/schemas', @schemasController.get
    app.get '/schemas/:key', @schemasController.get

    app.get '/authenticate', passport.authenticate('octoblu', {
      failureRedirect: '/authenticate/failed',
    })
    app.get '/authenticate/callback', passport.authenticate('octoblu', {
      failureRedirect: '/authenticate/failed',
    })
    app.get '/authenticate/failed', (request, response) =>
      response.status(403).send({ message: 'Unable to authenticate' })

module.exports = Router
