NodeRSA       = require 'node-rsa'
crypto        = require 'crypto'

class Encrypto
  constructor: ({ @privateKey, @publicKey }) ->
    @key = new NodeRSA @privateKey

  encrypt: (str) =>
    return @key.encryptPrivate(str)

  sign: (body) =>
    bodySignature = crypto.createHash('sha1')
      .update JSON.stringify(body)
      .digest 'hex'

    return @base64Encode @key.sign bodySignature

  base64Encode: (str) =>
    return new Buffer(str).toString('base64')

module.exports = Encrypto
