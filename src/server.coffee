_                  = require 'lodash'
cors               = require 'cors'
morgan             = require 'morgan'
express            = require 'express'
errorHandler       = require 'errorhandler'
bodyParser         = require 'body-parser'
enableDestroy      = require 'server-destroy'
alexa              = require './middlewares/alexa'
rawBody            = require './middlewares/raw-body'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
Router             = require './router'
debug              = require('debug')('alexa-service:server')

class Server
  constructor: (options)->
    {@disableLogging, @port} = options
    {@meshbluConfig,@alexaServiceUri} = options
    {@disableAlexaVerification} = options
    {@testCert} = options

  address: =>
    @server.address()

  run: (callback) =>
    app = express()
    app.use meshbluHealthcheck()
    app.use morgan 'dev', immediate: false unless @disableLogging
    app.use cors()
    app.use errorHandler()
    app.use rawBody.generate()
    app.use bodyParser.json limit : '1mb', defer: true

    app.options '*', cors()

    app.use '/trigger', alexa.verify { @testCert } unless @disableAlexaVerification

    router = new Router {@meshbluConfig,@alexaServiceUri}
    router.route app

    @server = app.listen @port, callback

    enableDestroy(@server)

  stop: (callback) =>
    @server.close callback

  destroy: =>
    @server.destroy()

module.exports = Server
