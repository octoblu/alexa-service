request       = require 'request'
enableDestroy = require 'server-destroy'
shmock        = require 'shmock'
uuid          = require 'uuid'
RedisNs       = require '@octoblu/redis-ns'
redis         = require 'ioredis'

Server         = require '../../src/server'
SessionHandler = require '../../src/handlers/session-handler'

describe 'Cancel Intent', ->
  beforeEach (done) ->
    @meshblu = shmock 0xd00d
    enableDestroy(@meshblu)

    meshbluConfig =
      server: 'localhost'
      port: 0xd00d
      protocol: 'http'
      keepAlive: false

    serverOptions =
      port: undefined,
      disableLogging: true
      meshbluConfig: meshbluConfig
      alexaServiceUri: 'https://alexa.octoblu.dev'
      namespace: 'alexa-service:test'
      timeoutSeconds: 1
      disableAlexaVerification: true

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

    client = new RedisNs 'alexa-service:test', redis.createClient(undefined, dropBufferSupport: true)
    @sessionHandler = new SessionHandler { client, timeoutSeconds: 1 }

  afterEach ->
    @meshblu.destroy()
    @server.destroy()

  describe 'POST /trigger', ->
    describe 'when the AMAZON.CancelIntent', ->
      describe 'when a session does NOT exist', ->
        beforeEach (done) ->
          userAuth = new Buffer('user-uuid:user-token').toString('base64')

          options =
            uri: '/trigger'
            baseUrl: "http://localhost:#{@serverPort}"
            json:
              session:
                sessionId: uuid.v1(),
                application:
                  applicationId: "application-id"
                user:
                  userId: "user-id",
                  accessToken: userAuth
                new: true
              request:
                type: "IntentRequest",
                requestId: uuid.v1(),
                timestamp: "2016-02-12T19:28:15Z",
                intent:
                  name: "AMAZON.CancelIntent"

          request.post options, (error, @response, @body) =>
            done error

        it 'should have a body', ->
          expect(@body).to.deep.equal
            version: '1.0'
            sessionAttributes: {}
            response:
              outputSpeech:
                type: 'SSML'
                ssml: '<speak>Closing session</speak>'
              shouldEndSession: true

        it 'should respond with 200', ->
          expect(@response.statusCode).to.equal 200

      describe 'when a session does exist', ->
        beforeEach (done) ->
          @sessionId = uuid.v1()
          userAuth = new Buffer('user-uuid:user-token').toString('base64')
          options =
            session:
              sessionId: @sessionId,
              application:
                applicationId: "application-id"
              user:
                userId: "user-id",
                accessToken: userAuth
              new: true
            request:
              type: "Something",
              requestId: uuid.v1(),
              timestamp: "2016-02-12T19:28:15Z",
              intent:
                name: "Something"
          @sessionHandler.create options, done

        beforeEach (done) ->
          userAuth = new Buffer('user-uuid:user-token').toString('base64')

          options =
            uri: '/trigger'
            baseUrl: "http://localhost:#{@serverPort}"
            json:
              session:
                sessionId: @sessionId,
                application:
                  applicationId: "application-id"
                user:
                  userId: "user-id",
                  accessToken: userAuth
                new: false
              request:
                type: "IntentRequest",
                requestId: uuid.v1(),
                timestamp: "2016-02-12T19:28:15Z",
                intent:
                  name: "AMAZON.CancelIntent"

          request.post options, (error, @response, @body) =>
            done error

        it 'should have a body', ->
          expect(@body).to.deep.equal
            version: '1.0'
            sessionAttributes: {}
            response:
              outputSpeech:
                type: 'SSML'
                ssml: '<speak>Closing session</speak>'
              shouldEndSession: true

        it 'should respond with 200', ->
          expect(@response.statusCode).to.equal 200

