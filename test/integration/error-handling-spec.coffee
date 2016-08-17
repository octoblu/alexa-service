request       = require 'request'
enableDestroy = require 'server-destroy'
shmock        = require 'shmock'
Server        = require '../../src/server'

describe 'HandleErrors', ->
  beforeEach (done) ->
    @restService = shmock 0xbabe
    @meshblu = shmock 0xd00d
    enableDestroy(@meshblu)
    enableDestroy(@restService)

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
      disableAlexaVerification: true

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

  afterEach ->
    @meshblu.destroy()
    @restService.destroy()
    @server.destroy()

  describe 'POST /dev/blow-up', ->
    describe 'when successful', ->
      beforeEach (done) ->
        options =
          uri: '/dev/blow-up'
          baseUrl: "http://localhost:#{@serverPort}"
          json: true

        request.post options, (error, @response, @body) =>
          done error

      it 'should have a body', ->
        expect(@body).to.deep.equal
          version: '1.0'
          response:
            outputSpeech:
              type: 'SSML'
              ssml: '<speak>Error: Oh No</speak>'
            shouldEndSession: true
          sessionAttributes: {}

      it 'should respond with 500', ->
        expect(@response.statusCode).to.equal 500
