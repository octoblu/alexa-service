{describe,beforeEach,afterEach,expect,it} = global
request       = require 'request'
enableDestroy = require 'server-destroy'
shmock        = require 'shmock'
uuid          = require 'uuid'
Server        = require '../../src/server'

describe 'List Triggers', ->
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
      disableAlexaVerification: true

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

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
          .send { owner: 'user-uuid', type: 'octoblu:flow', online: true }
          .reply 200, [
            {online: true, flow: nodes: [{name: 'sweet', type: 'operation:echo-in'}]}
            {online: true, flow: nodes: [{name: 'yay', type: 'operation:echo-in'}]}
          ]

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
                name: "ListTriggers"

        request.post options, (error, @response, @body) =>
          done error

      it 'should have a body', ->
        expect(@body).to.deep.equal
          version: '1.0'
          response:
            directives: []
            outputSpeech:
              type: 'SSML'
              ssml: '<speak>You have two available triggers, sweet and yay. Say sweet or yay to perform the action</speak>'
            shouldEndSession: true

      it 'should respond with 200', ->
        expect(@response.statusCode).to.equal 200

      it 'should hit up search your flows', ->
        @searchDevices.done()

      it 'should hit up whoami', ->
        @whoami.done()

  describe 'when missing any triggers', ->
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
        .send owner: 'user-uuid', type: 'octoblu:flow', online: true
        .reply 200, []

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
              name: "ListTriggers"

      request.post options, (error, @response, @body) =>
        done error

    it 'should have a body', ->
      expect(@body).to.deep.equal
        version: '1.0'
        response:
          directives: []
          outputSpeech:
            type: 'SSML'
            ssml: "<speak>You don't have any echo-in triggers. Get started by importing one or more alexa bluprints.</speak>"
          shouldEndSession: true

    it 'should respond with 200', ->
      expect(@response.statusCode).to.equal 200

    it 'should hit up get a list of flows', ->
      @searchDevices.done()

    it 'should hit up whoami', ->
      @whoami.done()

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
            sessionId: sessionId
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
              name: "ListTriggers"

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
