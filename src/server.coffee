cors               = require 'cors'
_                  = require 'lodash'
morgan             = require 'morgan'
express            = require 'express'
onFinished         = require 'on-finished'
bodyParser         = require 'body-parser'
errorHandler       = require 'errorhandler'
enableDestroy      = require 'server-destroy'
sendError          = require 'express-send-error'
expressVersion     = require 'express-package-version'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
RedisPooledClient  = require 'express-redis-pooled-client'

Router             = require './router'
alexa              = require './middlewares/alexa'
rawBody            = require './middlewares/raw-body'
debug              = require('debug')('alexa-service:server')

class Server
  constructor: (options)->
    {@disableLogging,@port} = options
    {@meshbluConfig,@alexaServiceUri} = options
    {@disableAlexaVerification} = options
    {@timeoutSeconds,@redisUri, @namespace} = options
    {@testCert} = options
    {@maxConnections,@minConnections} = options
    throw new Error 'Missing meshbluConfig' unless @meshbluConfig?
    throw new Error 'Missing namespace' unless @namespace?
    throw new Error 'Missing alexaServiceUri' unless @alexaServiceUri?
    @redisUri ?= 'redis://localhost:6379'
    @maxConnections ?= 10

  address: =>
    @server.address()

  run: (callback) =>
    app = express()
    app.use meshbluHealthcheck()
    app.use expressVersion { format: '{"version": "%s"}' }
    app.use sendError()
    app.use morgan 'dev', immediate: false unless @disableLogging
    app.use cors()
    app.use errorHandler()
    app.use rawBody.generate()
    app.use bodyParser.json limit : '1mb', defer: true

    redisPool = new RedisPooledClient {@namespace, @maxConnections, @minConnections,@redisUri}
    app.use redisPool.middleware

    app.options '*', cors()

    app.use '/trigger', alexa.verify { @testCert } unless @disableAlexaVerification

    router = new Router {@timeoutSeconds, @meshbluConfig, @alexaServiceUri }
    router.route app

    @server = app.listen @port, callback

    enableDestroy @server

  stop: (callback) =>
    @server.close callback

  destroy: =>
    @server.destroy()

module.exports = Server
