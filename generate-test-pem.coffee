NodeRSA = require 'node-rsa'
class GeneratePEM
  run: =>
    key = new NodeRSA({ b: 512 })
    key.generateKeyPair()
    testCerts = {}
    testCerts.publicKey = key.exportKey('public')
    testCerts.privateKey = key.exportKey('private')
    console.log(JSON.stringify(testCerts, null, 2))

new GeneratePEM().run()
