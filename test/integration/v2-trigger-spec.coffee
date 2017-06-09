{describe,beforeEach,afterEach,expect,it} = global
request        = require 'request'
enableDestroy  = require 'server-destroy'
shmock         = require 'shmock'
uuid           = require 'uuid'
redis          = require 'ioredis'
RedisNs        = require '@octoblu/redis-ns'

Server         = require '../../src/server'
SessionHandler = require '../../src/handlers/session-handler'

describe 'Trigger (v2)', ->
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
    @sessionHandler = new SessionHandler { timeoutSeconds: 1, client }

  afterEach ->
    @meshblu.destroy()
    @server.destroy()

  describe 'POST /v2/trigger', ->
    describe 'when successful', ->
      beforeEach (done) ->
        sessionId = uuid.v1()
        requestId = uuid.v1()
        deviceAuth = new Buffer('device-uuid:device-token').toString('base64')

        @authenticate = @meshblu
          .post '/authenticate'
          .set 'Authorization', "Basic #{deviceAuth}"
          .reply 200, uuid: 'device-uuid', token: 'device-token'

        @whoami = @meshblu
          .get '/v2/whoami'
          .set 'Authorization', "Basic #{deviceAuth}"
          .reply 200, uuid: 'device-uuid', token: 'device-token'

        data = {
          type: "IntentRequest",
          requestId: requestId,
          timestamp: "2016-02-12T19:28:15Z",
          intent:
            name: "Trigger",
            slots:
              Name:
                name: "Name",
                value: "the weather"
        }

        @message = @meshblu
          .post '/messages'
          .set 'Authorization', "Basic #{deviceAuth}"
          .send {
            devices: ['device-uuid']
            topic: 'echo-request'
            metadata:
              callbackUrl: "https://alexa.octoblu.dev/v2/respond/#{requestId}"
              callbackMethod: "POST"
              sessionId: sessionId
              responseId: requestId
              type: 'new'
            data: data
          }
          .reply 200

        body =
          metadata:
            jobType: 'Say'
            responseId: requestId
          data:
            phrase: 'THIS IS THE RESPONSE TEXT'

        @sessionHandler.respond { responseId: requestId, body }, (error) =>
          return done error if error?
          options =
            uri: '/v2/trigger'
            baseUrl: "http://localhost:#{@serverPort}"
            json:
              session:
                sessionId: sessionId,
                application:
                  applicationId: "application-id"
                user:
                  userId: "user-id",
                  accessToken: deviceAuth
                new: true
              request:
                type: "IntentRequest",
                requestId: requestId,
                timestamp: "2016-02-12T19:28:15Z",
                intent:
                  name: "Trigger",
                  slots:
                    Name:
                      name: "Name",
                      value: "the weather"

          request.post options, (error, @response, @body) =>
            done error

      it 'should have a body', ->
        expect(@body).to.deep.equal
          version: '1.0'
          response:
            directives: []
            outputSpeech:
              type: 'SSML'
              ssml: '<speak>THIS IS THE RESPONSE TEXT</speak>'
            shouldEndSession: true

      it 'should respond with 200', ->
        expect(@response.statusCode).to.equal 200

      it 'should hit up authenticate', ->
        @authenticate.done()

      it 'should hit up whoami', ->
        @whoami.done()

      it 'should message the flow', ->
        @message.done()

    describe 'when rest service times out', ->
      beforeEach (done) ->
        sessionId = uuid.v1()
        requestId = uuid.v1()
        @timeout 3000
        deviceAuth = new Buffer('device-uuid:device-token').toString('base64')

        @authenticate = @meshblu
          .post '/authenticate'
          .set 'Authorization', "Basic #{deviceAuth}"
          .reply 200, uuid: 'device-uuid', token: 'device-token'

        @whoami = @meshblu
          .get '/v2/whoami'
          .set 'Authorization', "Basic #{deviceAuth}"
          .reply 200, uuid: 'device-uuid', token: 'device-token'

        data = {
          type: "IntentRequest",
          requestId: requestId,
          timestamp: "2016-02-12T19:28:15Z",
          intent:
            name: "Trigger",
            slots:
              Name:
                name: "Name",
                value: "the weather"
        }

        @message = @meshblu
          .post '/messages'
          .set 'Authorization', "Basic #{deviceAuth}"
          .send {
            devices: ['device-uuid']
            topic: 'echo-request'
            metadata:
              callbackUrl: "https://alexa.octoblu.dev/v2/respond/#{requestId}"
              callbackMethod: "POST"
              responseId: requestId
              sessionId: sessionId
              type: 'new'
            data: data
          }
          .reply 200

        options =
          uri: '/v2/trigger'
          baseUrl: "http://localhost:#{@serverPort}"
          json:
            session:
              sessionId: sessionId,
              application:
                applicationId: "application-id"
              user:
                userId: "user-id",
                accessToken: deviceAuth
              new: true
            request:
              type: "IntentRequest",
              requestId: requestId,
              timestamp: "2016-02-12T19:28:15Z",
              intent:
                name: "Trigger",
                slots:
                  Name:
                    name: "Name",
                    value: "the weather"

        request.post options, (error, @response, @body) =>
          done error

      it 'should have the right response', ->
        expect(@response.statusCode).to.equal 200
        expect(@body).to.deep.equal
          version: '1.0'
          response:
            directives: []
            outputSpeech:
              type: 'SSML'
              ssml: '<speak>Response timeout exceeded</speak>'
            shouldEndSession: true

      it 'should hit up meshblu stuff', ->
        @authenticate.done()
        @whoami.done()
        @message.done()

    describe 'when missing auth', ->
      beforeEach (done) ->
        sessionId = uuid.v1()
        requestId = uuid.v1()
        @authenticate = @meshblu
          .post '/authenticate'
          .reply 403, error: message: 'Unauthorized'

        options =
          uri: '/v2/trigger'
          baseUrl: "http://localhost:#{@serverPort}"
          json:
            session:
              sessionId: sessionId,
              application:
                applicationId: "application-id"
              user:
                userId: "user-id",
              new: true
            request:
              type: "IntentRequest",
              requestId: requestId,
              timestamp: "2016-02-12T19:28:15Z",
              intent:
                name: "Trigger",
                slots:
                  Name:
                    name: "Name",
                    value: "the weather"

        request.post options, (error, @response, @body) =>
          done error

      it 'should have a body', ->
        expect(@body).to.deep.equal
          version: '1.0'
          response:
            directives: []
            outputSpeech:
              type: 'SSML'
              ssml: '<speak>Please go to your Alexa app and link your account.</speak>'
            card:
              type: 'LinkAccount'
            shouldEndSession: true

      it 'should respond with 200', ->
        expect(@response.statusCode).to.equal 200
