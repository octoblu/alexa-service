request        = require 'request'
redis          = require 'ioredis'
RedisNs        = require '@octoblu/redis-ns'

Server         = require '../../src/server'
SessionHandler = require '../../src/handlers/session-handler'

describe 'Respond', ->
  beforeEach (done) ->
    meshbluConfig =
      server: 'localhost'
      port: 0xd00d
      protocol: 'http'
      keepAlive: false

    serverOptions =
      port: undefined,
      disableLogging: true
      meshbluConfig: meshbluConfig
      timeoutSeconds: 1
      namespace: 'alexa-service:test'
      alexaServiceUri: 'https://alexa.octoblu.dev'
      disableAlexaVerification: false

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

    client = new RedisNs 'alexa-service:test', redis.createClient(undefined, dropBufferSupport: true)
    @sessionHandler = new SessionHandler { timeoutSeconds: 1, client }

  afterEach ->
    @server.destroy()

  describe 'POST /respond/:responseId', ->
    describe 'when successful', ->
      beforeEach (done) ->
        options =
          uri: '/respond/request-id'
          baseUrl: "http://localhost:#{@serverPort}"
          json:
            name: 'Freedom'

        request.post options, (error, @response, @body) =>
          throw error if error?
          @sessionHandler.listen { requestId: 'request-id' }, (error, @result) =>
            done error

      it 'should respond with 200', ->
        expect(@response.statusCode).to.equal 200

      it 'should have a body', ->
        expect(@body).to.deep.equal success: true

      it 'should have the response of Freedom', ->
        expect(@result.name).to.equal 'Freedom'

    describe 'when incorrect job key', ->
      beforeEach (done) ->
        @timeout 3000
        options =
          uri: '/respond/wrong-response-id'
          baseUrl: "http://localhost:#{@serverPort}"
          json:
            name: 'Freedom'

        request.post options, (error, @response, @body) =>
          throw error if error?
          @sessionHandler.listen { requestId: 'right-response-id' }, (@error) =>
            done()

      it 'should have a timeout error', ->
        expect(@error.message).to.equal 'Response timeout exceeded'
