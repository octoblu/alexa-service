_                  = require 'lodash'
AlexaController    = require './controllers/alexa-controller'

class Router
  constructor: ({jobManager, meshbluConfig, alexaServiceUri}) ->
    throw new Error 'Missing meshbluConfig' unless meshbluConfig?
    throw new Error 'Missing alexaServiceUri' unless alexaServiceUri?
    throw new Error 'Missing jobManager' unless jobManager?
    @alexaController = new AlexaController {jobManager, meshbluConfig, alexaServiceUri}

  doAndHandleErrors: (route) =>
    return (req, res) =>
      try
        route req, res
      catch error
        console.error error
        { response } = @alexaController.createRequestAndResponse req
        @alexaController.handleError res, response, error

  route: (app) =>
    app.post '/trigger', @doAndHandleErrors @alexaController.trigger
    app.post '/respond/:responseId', @doAndHandleErrors @alexaController.respond
    app.post '/dev/blow-up', @doAndHandleErrors () =>
      throw new Error('Oh No')

module.exports = Router
