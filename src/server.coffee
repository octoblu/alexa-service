cors               = require 'cors'
morgan             = require 'morgan'
express            = require 'express'
bodyParser         = require 'body-parser'
errorHandler       = require 'errorhandler'
enableDestroy      = require 'server-destroy'
sendError          = require 'express-send-error'
expressVersion     = require 'express-package-version'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
RedisPooledClient  = require 'express-redis-pooled-client'

Router             = require './router'
verifier           = require 'alexa-verifier-middleware'

class Server
  constructor: (options)->
    {@disableLogging,@port} = options
    {@meshbluConfig,@alexaServiceUri} = options
    {@disableAlexaVerification} = options
    {@timeoutSeconds,@redisUri, @namespace} = options
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

    redisPool = new RedisPooledClient {@namespace, @maxConnections, @minConnections,@redisUri}
    app.use redisPool.middleware()
    app.use '/proofoflife', redisPool.proofoflife()

    app.options '*', cors()

    app.use '/trigger', verifier unless @disableAlexaVerification
    app.use '/v2/trigger', verifier unless @disableAlexaVerification
    app.use bodyParser.json limit : '1mb'

    router = new Router {@timeoutSeconds, @meshbluConfig, @alexaServiceUri }
    router.route app

    @server = app.listen @port, callback

    enableDestroy @server

  stop: (callback) =>
    @server.close callback

  destroy: =>
    @server.destroy()

module.exports = Server
