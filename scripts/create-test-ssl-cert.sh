#!/bin/bash

main() {
  rm ./test/certs/*.pem
  mkdir -p ./test/certs
  openssl genrsa -out ./test/certs/alexa-key.pem 1024
  openssl req -new -key ./test/certs/alexa-key.pem -out ./test/certs/alexa-csr.pem
  openssl x509 -req -in ./test/certs/alexa-csr.pem -signkey ./test/certs/alexa-key.pem -out ./test/certs/alexa-cert.pem
}

main "$@"
