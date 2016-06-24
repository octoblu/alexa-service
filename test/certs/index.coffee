fs   = require 'fs'
path = require 'path'

certsDir = path.join __dirname, '..', 'certs'
certs = {}
certs.crt = fs.readFileSync(path.join(certsDir, 'alexa-cert.pem')).toString()
certs.csr = fs.readFileSync(path.join(certsDir, 'alexa-csr.pem')).toString()
certs.key = fs.readFileSync(path.join(certsDir, 'alexa-key.pem')).toString()

module.exports = certs
