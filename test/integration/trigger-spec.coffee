request        = require 'request'
enableDestroy  = require 'server-destroy'
shmock         = require 'shmock'
uuid           = require 'uuid'
redis          = require 'redis'
RedisNs        = require '@octoblu/redis-ns'

Server         = require '../../src/server'
SessionHandler = require '../../src/handlers/session-handler'

describe 'Trigger', ->
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

    client = new RedisNs 'alexa-service:test', redis.createClient()
    @sessionHandler = new SessionHandler { timeoutSeconds: 1, client }

  afterEach ->
    @meshblu.destroy()
    @server.destroy()

  describe 'POST /trigger', ->
    describe 'when successful', ->
      beforeEach (done) ->
        sessionId = uuid.v1()
        requestId = uuid.v1()
        userAuth = new Buffer('user-uuid:user-token').toString('base64')

        @whoami = @meshblu
          .post '/authenticate'
          .set 'Authorization', "Basic #{userAuth}"
          .reply 200, uuid: 'user-uuid', token: 'user-token'

        @searchDevices = @meshblu
          .post '/search/devices'
          .set 'Authorization', "Basic #{userAuth}"
          .set 'X-MESHBLU-PROJECTION', JSON.stringify { uuid: true, 'flow.nodes': true }
          .send { owner: 'user-uuid', online: true, type: 'octoblu:flow' }
          .reply 200, [
            {
              uuid: 'hello',
              flow: {
                nodes: [
                  {
                    id: 'weather',
                    type: 'operation:echo-in',
                    name: 'the weather'
                  }
                  {
                    id: 'trip-report',
                    type: 'operation:echo-in',
                    name: 'the trip report'
                  }
                ]
              }
            }
            {
              uuid: 'bye',
              flow: {
                nodes: [
                  {
                    id: 'stock',
                    type: 'operation:echo-in',
                    name: 'the stock price'
                  }
                ]
              }
            }
          ]

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
          .set 'Authorization', "Basic #{userAuth}"
          .send {
            devices: ['hello']
            topic: 'triggers-service'
            payload:
              callbackUrl: "https://alexa.octoblu.dev/respond/#{requestId}"
              callbackMethod: "POST"
              sessionId: sessionId
              responseId: requestId
              from: 'weather'
              type: 'new'
              params: data
              payload: data
          }
          .reply 200

        body = {
          responseText: 'THIS IS THE RESPONSE TEXT'
        }
        @sessionHandler.respond { responseId: requestId, body }, (error) =>
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
          sessionAttributes: {}
          response:
            outputSpeech:
              type: 'SSML'
              ssml: '<speak>THIS IS THE RESPONSE TEXT</speak>'
            shouldEndSession: true

      it 'should respond with 200', ->
        expect(@response.statusCode).to.equal 200

      it 'should hit up whoami', ->
        @whoami.done()

      it 'should search for flows', ->
        @searchDevices.done()

      it 'should message the flow', ->
        @message.done()

    describe 'when rest service times out', ->
      beforeEach (done) ->
        sessionId = uuid.v1()
        requestId = uuid.v1()
        @timeout 3000
        userAuth = new Buffer('user-uuid:user-token').toString('base64')

        @whoami = @meshblu
          .post '/authenticate'
          .set 'Authorization', "Basic #{userAuth}"
          .reply 200, uuid: 'user-uuid', token: 'user-token'

        @searchDevices = @meshblu
          .post '/search/devices'
          .set 'Authorization', "Basic #{userAuth}"
          .set 'X-MESHBLU-PROJECTION', JSON.stringify { uuid: true, 'flow.nodes': true }
          .send { owner: 'user-uuid', online: true, type: 'octoblu:flow' }
          .reply 200, [
            {
              uuid: 'hello',
              flow: {
                nodes: [
                  {
                    id: 'weather',
                    type: 'operation:echo-in',
                    name: 'the weather'
                  }
                ]
              }
            }
          ]

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
          .set 'Authorization', "Basic #{userAuth}"
          .send {
            devices: ['hello']
            topic: 'triggers-service'
            payload:
              callbackUrl: "https://alexa.octoblu.dev/respond/#{requestId}"
              callbackMethod: "POST"
              responseId: requestId
              sessionId: sessionId
              from: 'weather'
              type: 'new'
              params: data
              payload: data
          }
          .reply 200

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
          sessionAttributes: {}
          response:
            outputSpeech:
              type: 'SSML'
              ssml: '<speak>Response timeout exceeded</speak>'
            shouldEndSession: true

      it 'should hit up meshblu stuff', ->
        @whoami.done()
        @searchDevices.done()
        @message.done()

    describe 'when missing auth', ->
      beforeEach (done) ->
        sessionId = uuid.v1()
        requestId = uuid.v1()
        @whoami = @meshblu
          .post '/authenticate'
          .reply 403, error: message: 'Unauthorized'

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
          sessionAttributes: {}
          response:
            outputSpeech:
              type: 'SSML'
              ssml: '<speak>Please go to your Alexa app and link your account.</speak>'
            card:
              type: 'LinkAccount'
            shouldEndSession: true

      it 'should respond with 200', ->
        expect(@response.statusCode).to.equal 200

