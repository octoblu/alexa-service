request    = require 'request'
shmock     = require '@octoblu/shmock'
Server     = require '../../src/server'

describe 'List Triggers', ->
  beforeEach (done) ->
    @restService = shmock 0xbabe
    @meshblu = shmock 0xd00d

    meshbluConfig =
      server: 'localhost'
      port: 0xd00d
      protocol: 'http'
      keepAlive: false

    serverOptions =
      port: undefined,
      disableLogging: true
      meshbluConfig: meshbluConfig
      restServiceUri: "http://localhost:#{0xbabe}"

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

  afterEach (done) ->
    @server.stop done

  afterEach (done) ->
    @restService.close done

  afterEach (done) ->
    @meshblu.close done

  describe 'POST /trigger', ->
    describe 'when successful', ->
      beforeEach (done) ->
        userAuth = new Buffer('user-uuid:user-token').toString('base64')

        @whoami = @meshblu
          .post '/authenticate'
          .set 'Authorization', "Basic #{userAuth}"
          .reply 200, uuid: 'user-uuid', token: 'user-token'

        @getDevices = @meshblu
          .get '/v2/devices'
          .set 'Authorization', "Basic #{userAuth}"
          .query owner: 'user-uuid', type: 'octoblu:flow', online: 'true'
          .reply 200, [
            {online: true, flow: nodes: [{name: 'sweet', type: 'operation:echo-in'}]}
            {online: true, flow: nodes: [{name: 'yay', type: 'operation:echo-in'}]}
          ]

        options =
          uri: '/trigger'
          baseUrl: "http://localhost:#{@serverPort}"
          json:
            session:
              sessionId: "session-id",
              application:
                applicationId: "application-id"
              user:
                userId: "user-id",
                accessToken: userAuth
              new: true
            request:
              type: "IntentRequest",
              requestId: "request-id",
              timestamp: "2016-02-12T19:28:15Z",
              intent:
                name: "ListTriggers"

        request.post options, (error, @response, @body) =>
          done error

      it 'should have a body', ->
        expect(@body).to.deep.equal
          version: '1.0'
          response:
            outputSpeech:
              type: 'PlainText'
              text: 'Your triggers are sweet, and yay. Say a trigger name to perform the action'
            shouldEndSession: true

      it 'should respond with 200', ->
        expect(@response.statusCode).to.equal 200

      it 'should hit up the rest service', ->
        @getDevices.done()

      it 'should hit up whoami', ->
        @whoami.done()

    describe 'when the AMAZON.HelpIntent', ->
      beforeEach (done) ->
        userAuth = new Buffer('user-uuid:user-token').toString('base64')

        @whoami = @meshblu
          .post '/authenticate'
          .set 'Authorization', "Basic #{userAuth}"
          .reply 200, uuid: 'user-uuid', token: 'user-token'

        @getDevices = @meshblu
          .get '/v2/devices'
          .set 'Authorization', "Basic #{userAuth}"
          .query owner: 'user-uuid', type: 'octoblu:flow', online: 'true'
          .reply 200, [
            {flow: nodes: [{name: 'sweet', type: 'operation:echo-in'}]}
            {flow: nodes: [{name: 'yay', type: 'operation:echo-in'}]}
          ]

        options =
          uri: '/trigger'
          baseUrl: "http://localhost:#{@serverPort}"
          json:
            session:
              sessionId: "session-id",
              application:
                applicationId: "application-id"
              user:
                userId: "user-id",
                accessToken: userAuth
              new: true
            request:
              type: "IntentRequest",
              requestId: "request-id",
              timestamp: "2016-02-12T19:28:15Z",
              intent:
                name: "AMAZON.HelpIntent"

        request.post options, (error, @response, @body) =>
          done error

      it 'should have a body', ->
        expect(@body).to.deep.equal
          version: '1.0'
          response:
            outputSpeech:
              type: 'PlainText'
              text: 'This skill allows you to trigger an Octoblu flow that perform a series of events or actions. Currently, Your triggers are sweet, and yay. Say a trigger name to perform the action'
            shouldEndSession: false

      it 'should respond with 200', ->
        expect(@response.statusCode).to.equal 200

      it 'should hit up the rest service', ->
        @getDevices.done()

      it 'should hit up whoami', ->
        @whoami.done()

  describe 'when missing any triggers', ->
    beforeEach (done) ->
      userAuth = new Buffer('user-uuid:user-token').toString('base64')

      @whoami = @meshblu
        .post '/authenticate'
        .set 'Authorization', "Basic #{userAuth}"
        .reply 200, uuid: 'user-uuid', token: 'user-token'

      @getDevices = @meshblu
        .get '/v2/devices'
        .set 'Authorization', "Basic #{userAuth}"
        .query owner: 'user-uuid', type: 'octoblu:flow', online: 'true'
        .reply 200, []

      options =
        uri: '/trigger'
        baseUrl: "http://localhost:#{@serverPort}"
        json:
          session:
            sessionId: "session-id",
            application:
              applicationId: "application-id"
            user:
              userId: "user-id",
              accessToken: userAuth
            new: true
          request:
            type: "IntentRequest",
            requestId: "request-id",
            timestamp: "2016-02-12T19:28:15Z",
            intent:
              name: "ListTriggers"

      request.post options, (error, @response, @body) =>
        done error

    it 'should have a body', ->
      expect(@body).to.deep.equal
        version: '1.0'
        response:
          outputSpeech:
            type: 'PlainText'
            text: "You don't have any echo-in triggers. Get started by importing one or more alexa bluprints."
          shouldEndSession: true

    it 'should respond with 200', ->
      expect(@response.statusCode).to.equal 200

    it 'should hit up the rest service', ->
      @getDevices.done()

    it 'should hit up whoami', ->
      @whoami.done()
