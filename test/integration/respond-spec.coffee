request       = require 'request'
Server        = require '../../src/server'

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
      alexaServiceUri: 'https://alexa.octoblu.dev'
      disableAlexaVerification: false

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

  afterEach ->
    @server.destroy()

  describe 'POST /respond/:responseId', ->
    beforeEach (done) ->
      options =
        uri: '/respond/my-response-id'
        baseUrl: "http://localhost:#{@serverPort}"
        json:
          name: 'Freedom'

      request.post options, (error, @response, @body) =>
        done error

    it 'should respond with 200', ->
      expect(@response.statusCode).to.equal 200

    it 'should have a body', ->
      expect(@body).to.deep.equal success: true
