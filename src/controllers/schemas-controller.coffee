schemas = require '../schemas'

class SchemasController
  get: (request, response) =>
    { key } = request.params
    result = schemas[key] if key?
    result ?= schemas
    return response.sendStatus(404) unless result?
    response.send(result)
  
module.exports = SchemasController
