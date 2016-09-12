request        = require 'request'
enableDestroy  = require 'server-destroy'
shmock         = require 'shmock'
uuid           = require 'uuid'
redis          = require 'ioredis'
RedisNs        = require '@octoblu/redis-ns'

Server         = require '../../src/server'
SessionHandler = require '../../src/handlers/session-handler'

describe 'Conversation', ->
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

  describe 'POST /trigger', ->
    describe 'when a conversation is started', ->
      beforeEach (done) ->
        @sessionId = uuid.v1()
        userAuth = new Buffer('user-uuid:user-token').toString('base64')

        @whoami = @meshblu
          .post '/authenticate'
          .set 'Authorization', "Basic #{userAuth}"
          .reply 200, uuid: 'user-uuid', token: 'user-token'

        @searchFlows = @meshblu
          .post '/search/devices'
          .set 'Authorization', "Basic #{userAuth}"
          .set 'X-MESHBLU-PROJECTION', JSON.stringify { uuid: true, 'flow.nodes': true }
          .send { owner: 'user-uuid', online: true, type: 'octoblu:flow' }
          .reply 200, [
            {
              uuid: 'hello-flow',
              flow: {
                nodes: [
                  {
                    id: 'hello-id',
                    type: 'operation:echo-in',
                    name: 'hello'
                  }
                ]
              }
            }
          ]

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
          .set 'Authorization', "Basic #{userAuth}"
          .send {
            devices: ['hello-flow']
            topic: 'triggers-service'
            payload:
              callbackUrl: "https://alexa.octoblu.dev/respond/#{responseId}"
              callbackMethod: "POST"
              responseId: responseId
              sessionId: @sessionId
              from: 'hello-id'
              type: 'new'
              params: alexaRequest
              payload: alexaRequest
          }
          .reply 200

        body =
          response:
            outputSpeech:
              type: 'SSML'
              ssml: '<speak>Hello</speak>'
            shouldEndSession: false

        @sessionHandler.respond { responseId, body }, (error) =>
          return done error if error?
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
                new: true
              request: alexaRequest

          request.post options, (error, @response, @body) =>
            done error

      it 'should have a body', ->
        expect(@body).to.deep.equal
          version: '1.0'
          sessionAttributes: {}
          response:
            outputSpeech:
              type: 'SSML'
              ssml: '<speak>Hello</speak>'
            shouldEndSession: false

      it 'should respond with 200', ->
        expect(@response.statusCode).to.equal 200

      it 'should hit up the meshblu stuff', ->
        @whoami.done()
        @searchFlows.done()
        @message.done()

      describe 'when a different session is started', ->
        beforeEach (done) ->
          sessionId = uuid.v1()
          userAuth = new Buffer('user-uuid:user-token').toString('base64')

          @whoami = @meshblu
            .post '/authenticate'
            .set 'Authorization', "Basic #{userAuth}"
            .reply 200, uuid: 'user-uuid', token: 'user-token'

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

          @searchFlows = @meshblu
            .post '/search/devices'
            .set 'Authorization', "Basic #{userAuth}"
            .set 'X-MESHBLU-PROJECTION', JSON.stringify { uuid: true, 'flow.nodes': true }
            .send { owner: 'user-uuid', online: true, type: 'octoblu:flow' }
            .reply 200, [
              {
                uuid: 'yeah-flow',
                flow: {
                  nodes: [
                    {
                      id: 'yeah-id',
                      type: 'operation:echo-in',
                      name: 'yeah'
                    }
                  ]
                }
              }
            ]


          @message = @meshblu
            .post '/messages'
            .set 'Authorization', "Basic #{userAuth}"
            .send {
              devices: ['yeah-flow']
              topic: 'triggers-service'
              payload:
                callbackUrl: "https://alexa.octoblu.dev/respond/#{responseId}"
                callbackMethod: "POST"
                responseId: responseId
                sessionId: sessionId
                from: 'yeah-id'
                type: 'new'
                params: alexaRequest
                payload: alexaRequest
            }
            .reply 200

          body =
            response:
              outputSpeech:
                type: 'SSML'
                ssml: '<speak>Another</speak>'
              shouldEndSession: true

          @sessionHandler.respond { responseId, body }, (error) =>
            return done error if error?
            options =
              uri: '/trigger'
              baseUrl: "http://localhost:#{@serverPort}"
              json:
                session:
                  sessionId: sessionId,
                  application:
                    applicationId: "application-id"
                  user:
                    userId: "user-id",
                    accessToken: userAuth
                  new: true
                request: alexaRequest

            request.post options, (error, @response, @body) =>
              done error

        it 'should have a body', ->
          expect(@body).to.deep.equal
            version: '1.0'
            sessionAttributes: {}
            response:
              outputSpeech:
                type: 'SSML'
                ssml: '<speak>Another</speak>'
              shouldEndSession: true

        it 'should respond with 200', ->
          expect(@response.statusCode).to.equal 200

        it 'should hit up the meshblu stuff', ->
          @whoami.done()
          @searchFlows.done()
          @message.done()

      describe 'when a reply is made', ->
        beforeEach (done) ->
          userAuth = new Buffer('user-uuid:user-token').toString('base64')

          @whoami = @meshblu
            .post '/authenticate'
            .set 'Authorization', "Basic #{userAuth}"
            .reply 200, uuid: 'user-uuid', token: 'user-token'

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
            .set 'Authorization', "Basic #{userAuth}"
            .send {
              devices: ['hello-flow']
              topic: 'triggers-service'
              payload:
                callbackUrl: "https://alexa.octoblu.dev/respond/#{responseId}"
                callbackMethod: "POST"
                responseId: responseId
                sessionId: @sessionId
                from: 'hello-id'
                type: 'reply'
                params: alexaRequest
                payload: alexaRequest
            }
            .reply 200

          body =
            response:
              outputSpeech:
                type: 'SSML'
                ssml: '<speak>Howdy</speak>'
              shouldEndSession: false

          @sessionHandler.respond { responseId, body }, (error) =>
            return done error if error?
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
                request: alexaRequest

            request.post options, (error, @response, @body) =>
              done error

        it 'should have a body', ->
          expect(@body).to.deep.equal
            version: '1.0'
            sessionAttributes: {}
            response:
              outputSpeech:
                type: 'SSML'
                ssml: '<speak>Howdy</speak>'
              shouldEndSession: false

        it 'should respond with 200', ->
          expect(@response.statusCode).to.equal 200

        it 'should hit up the meshblu stuff', ->
          @whoami.done()
          @message.done()

        describe 'when a closing reply is made', ->
          beforeEach (done) ->
            userAuth = new Buffer('user-uuid:user-token').toString('base64')

            @whoami = @meshblu
              .post '/authenticate'
              .set 'Authorization', "Basic #{userAuth}"
              .reply 200, uuid: 'user-uuid', token: 'user-token'

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
              .set 'Authorization', "Basic #{userAuth}"
              .send {
                devices: ['hello-flow']
                topic: 'triggers-service'
                payload:
                  callbackUrl: "https://alexa.octoblu.dev/respond/#{responseId}"
                  callbackMethod: "POST"
                  responseId: responseId
                  sessionId: @sessionId
                  from: 'hello-id'
                  type: 'reply'
                  params: alexaRequest
                  payload: alexaRequest
              }
              .reply 200

            body =
              response:
                outputSpeech:
                  type: 'SSML'
                  ssml: '<speak>I am closing</speak>'
                shouldEndSession: true

            @sessionHandler.respond { responseId, body }, (error) =>
              return done error if error?
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
                  request: alexaRequest

              request.post options, (error, @response, @body) =>
                done error

          it 'should have a body', ->
            expect(@body).to.deep.equal
              version: '1.0'
              sessionAttributes: {}
              response:
                outputSpeech:
                  type: 'SSML'
                  ssml: '<speak>I am closing</speak>'
                shouldEndSession: true

          it 'should respond with 200', ->
            expect(@response.statusCode).to.equal 200

          it 'should hit up the meshblu stuff', ->
            @whoami.done()
            @message.done()
