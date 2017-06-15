{describe,beforeEach,afterEach,expect,it} = global
request        = require 'request'
enableDestroy  = require 'server-destroy'
shmock         = require 'shmock'
uuid           = require 'uuid'
redis          = require 'ioredis'
RedisNs        = require '@octoblu/redis-ns'

Server         = require '../../src/server'
SessionHandler = require '../../src/handlers/session-handler'

describe 'Conversation (v2)', ->
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
    @sessionHandler = new SessionHandler { timeoutSeconds: 1, client, alexaServiceUri: 'https://alexa.octoblu.dev' }

  afterEach ->
    @meshblu.destroy()
    @server.destroy()

  describe 'POST /v2/trigger', ->
    describe 'when a conversation is started', ->
      beforeEach (done) ->
        @sessionId = uuid.v1()
        deviceAuth = new Buffer('device-uuid:device-token').toString('base64')

        @authenticate = @meshblu
          .post '/authenticate'
          .set 'Authorization', "Basic #{deviceAuth}"
          .reply 200, uuid: 'device-uuid', token: 'device-token'

        @whoami = @meshblu
          .get '/v2/whoami'
          .set 'Authorization', "Basic #{deviceAuth}"
          .reply 200, uuid: 'device-uuid', token: 'device-token'

        responseId = uuid.v1()
        alexaRequest = {
          type: "IntentRequest",
          requestId: responseId,
          timestamp: "2016-02-12T19:28:15Z",
          intent:
            name: "Trigger",
            slots:
              Name:
                name: "Name",
                value: "hello"
        }

        @message = @meshblu
          .post '/messages'
          .set 'Authorization', "Basic #{deviceAuth}"
          .send {
            devices: ['device-uuid']
            topic: 'echo-request'
            metadata:
              callbackUrl: "https://alexa.octoblu.dev/v2/respond/#{responseId}"
              callbackMethod: "POST"
              responseId: responseId
              sessionId: @sessionId
              type: 'new'
            data: alexaRequest
          }
          .reply 200

        body =
          metadata:
            jobType: 'Say'
            responseId: responseId
            endSession: false
          data:
            phrase: 'Hello'

        @sessionHandler.respond { responseId, body }, (error) =>
          return done error if error?
          options =
            uri: '/v2/trigger'
            baseUrl: "http://localhost:#{@serverPort}"
            json:
              session:
                sessionId: @sessionId,
                application:
                  applicationId: "application-id"
                user:
                  userId: "user-id",
                  accessToken: deviceAuth
                new: true
              request: alexaRequest

          request.post options, (error, @response, @body) =>
            done error

      it 'should have a body', ->
        expect(@body).to.deep.equal
          version: '1.0'
          response:
            directives: []
            outputSpeech:
              type: 'SSML'
              ssml: '<speak>Hello</speak>'
            shouldEndSession: false

      it 'should respond with 200', ->
        expect(@response.statusCode).to.equal 200

      it 'should hit up the meshblu stuff', ->
        @authenticate.done()
        @whoami.done()
        @message.done()

      describe 'when a different session is started', ->
        beforeEach (done) ->
          sessionId = uuid.v1()
          deviceAuth = new Buffer('device-uuid:device-token').toString('base64')

          @authenticate = @meshblu
            .post '/authenticate'
            .set 'Authorization', "Basic #{deviceAuth}"
            .reply 200, uuid: 'device-uuid', token: 'device-token'

          @whoami = @meshblu
            .get '/v2/whoami'
            .set 'Authorization', "Basic #{deviceAuth}"
            .reply 200, uuid: 'device-uuid', token: 'device-token'

          responseId = uuid.v1()
          alexaRequest = {
            type: "IntentRequest",
            requestId: responseId,
            timestamp: "2016-02-12T19:28:15Z",
            intent:
              name: "Trigger",
              slots:
                Name:
                  name: "Name",
                  value: "yeah"
          }

          @message = @meshblu
            .post '/messages'
            .set 'Authorization', "Basic #{deviceAuth}"
            .send {
              devices: ['device-uuid']
              topic: 'echo-request'
              metadata:
                callbackUrl: "https://alexa.octoblu.dev/v2/respond/#{responseId}"
                callbackMethod: "POST"
                responseId: responseId
                sessionId: sessionId
                type: 'new'
              data: alexaRequest
            }
            .reply 200

          body =
            metadata:
              jobType: 'Say'
              responseId: responseId
              endSession: true
            data:
              phrase: 'Another'

          @sessionHandler.respond { responseId, body }, (error) =>
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
                request: alexaRequest

            request.post options, (error, @response, @body) =>
              done error

        it 'should have a body', ->
          expect(@body).to.deep.equal
            version: '1.0'
            response:
              directives: []
              outputSpeech:
                type: 'SSML'
                ssml: '<speak>Another</speak>'
              shouldEndSession: true

        it 'should respond with 200', ->
          expect(@response.statusCode).to.equal 200

        it 'should hit up the meshblu stuff', ->
          @authenticate.done()
          @whoami.done()
          @message.done()

      describe 'when a reply is made', ->
        beforeEach (done) ->
          deviceAuth = new Buffer('device-uuid:device-token').toString('base64')

          @authenticate = @meshblu
            .post '/authenticate'
            .set 'Authorization', "Basic #{deviceAuth}"
            .reply 200, uuid: 'device-uuid', token: 'device-token'

          @whoami = @meshblu
            .get '/v2/whoami'
            .set 'Authorization', "Basic #{deviceAuth}"
            .reply 200, uuid: 'device-uuid', token: 'device-token'

          responseId = uuid.v1()
          alexaRequest = {
            type: "IntentRequest",
            requestId: responseId,
            timestamp: "2016-02-12T19:28:15Z",
            intent:
              name: "Bacon",
              slots:
                Name:
                  name: "Name",
                  value: "howdy"
          }

          @message = @meshblu
            .post '/messages'
            .set 'Authorization', "Basic #{deviceAuth}"
            .send {
              devices: ['device-uuid']
              topic: 'echo-request'
              metadata:
                callbackUrl: "https://alexa.octoblu.dev/v2/respond/#{responseId}"
                callbackMethod: "POST"
                responseId: responseId
                sessionId: @sessionId
                type: 'reply'
              data: alexaRequest
            }
            .reply 200

          body =
            metadata:
              jobType: 'Say'
              responseId: responseId
              endSession: false
            data:
              phrase: 'Howdy'

          @sessionHandler.respond { responseId, body }, (error) =>
            return done error if error?
            options =
              uri: '/v2/trigger'
              baseUrl: "http://localhost:#{@serverPort}"
              json:
                session:
                  sessionId: @sessionId,
                  application:
                    applicationId: "application-id"
                  user:
                    userId: "user-id",
                    accessToken: deviceAuth
                  new: false
                request: alexaRequest

            request.post options, (error, @response, @body) =>
              done error

        it 'should have a body', ->
          expect(@body).to.deep.equal
            version: '1.0'
            response:
              directives: []
              outputSpeech:
                type: 'SSML'
                ssml: '<speak>Howdy</speak>'
              shouldEndSession: false

        it 'should respond with 200', ->
          expect(@response.statusCode).to.equal 200

        it 'should hit up the meshblu stuff', ->
          @authenticate.done()
          @message.done()

        describe 'when a closing reply is made', ->
          beforeEach (done) ->
            deviceAuth = new Buffer('device-uuid:device-token').toString('base64')

            @authenticate = @meshblu
              .post '/authenticate'
              .set 'Authorization', "Basic #{deviceAuth}"
              .reply 200, uuid: 'device-uuid', token: 'device-token'

            @whoami = @meshblu
              .get '/v2/whoami'
              .set 'Authorization', "Basic #{deviceAuth}"
              .reply 200, uuid: 'device-uuid', token: 'device-token'

            responseId = uuid.v1()
            alexaRequest = {
              type: "IntentRequest",
              requestId: responseId,
              timestamp: "2016-02-12T19:28:15Z",
              intent:
                name: "Answer",
                slots:
                  Taco:
                    name: "Taco",
                    value: "taco"
            }

            @message = @meshblu
              .post '/messages'
              .set 'Authorization', "Basic #{deviceAuth}"
              .send {
                devices: ['device-uuid']
                topic: 'echo-request'
                metadata:
                  callbackUrl: "https://alexa.octoblu.dev/v2/respond/#{responseId}"
                  callbackMethod: "POST"
                  responseId: responseId
                  sessionId: @sessionId
                  type: 'reply'
                data: alexaRequest
              }
              .reply 200

            body =
              metadata:
                jobType: 'Say'
                responseId: responseId
                endSession: true
              data:
                phrase: 'I am closing'

            @sessionHandler.respond { responseId, body }, (error) =>
              return done error if error?
              options =
                uri: '/v2/trigger'
                baseUrl: "http://localhost:#{@serverPort}"
                json:
                  session:
                    sessionId: @sessionId,
                    application:
                      applicationId: "application-id"
                    user:
                      userId: "user-id",
                      accessToken: deviceAuth
                    new: false
                  request: alexaRequest

              request.post options, (error, @response, @body) =>
                done error

          it 'should have a body', ->
            expect(@body).to.deep.equal
              version: '1.0'
              response:
                directives: []
                outputSpeech:
                  type: 'SSML'
                  ssml: '<speak>I am closing</speak>'
                shouldEndSession: true

          it 'should respond with 200', ->
            expect(@response.statusCode).to.equal 200

          it 'should hit up the meshblu stuff', ->
            @authenticate.done()
            @message.done()
