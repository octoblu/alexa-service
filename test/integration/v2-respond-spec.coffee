{describe,beforeEach,afterEach,expect,it} = global
request        = require 'request'
redis          = require 'ioredis'
RedisNs        = require '@octoblu/redis-ns'

Server         = require '../../src/server'
SessionHandler = require '../../src/handlers/session-handler'

describe 'Respond (v2)', ->
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

  describe 'POST /v2/respond', ->
    describe 'when successful', ->
      beforeEach (done) ->
        options =
          uri: '/v2/respond'
          baseUrl: "http://localhost:#{@serverPort}"
          json:
            metadata:
              responseId: 'right-request-id'
              jobType: 'Say'
            data:
              phrase: 'Freedom'

        request.post options, (error, @response, @body) =>
          throw error if error?
          @sessionHandler.listen { requestId: 'right-request-id' }, (error, @result) =>
            done error

      it 'should respond with 200', ->
        expect(@response.statusCode).to.equal 200

      it 'should have a body', ->
        expect(@body).to.deep.equal success: true

      it 'should have the response of Freedom', ->
        expect(@result.data.phrase).to.equal 'Freedom'

    describe 'when incorrect job key', ->
      beforeEach (done) ->
        @timeout 3000
        options =
          uri: '/v2/respond'
          baseUrl: "http://localhost:#{@serverPort}"
          json:
            metadata:
              responseId: 'wrong-response-id'
              jobType: 'Say'
            data:
              phrase: 'Terrible'

        request.post options, (error, @response, @body) =>
          throw error if error?
          @sessionHandler.listen { requestId: 'right-request-id' }, (@error) =>
            done()

      it 'should have a timeout error', ->
        expect(@error.message).to.equal 'Response timeout exceeded'
