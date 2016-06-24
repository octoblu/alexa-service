crypto        = require 'crypto'

class Encrypto
  constructor: ({ @key }) ->

  sign: (json) =>
    sign = crypto.createSign 'SHA1'
    sign.update JSON.stringify json
    return sign.sign @key, 'base64'

module.exports = Encrypto
