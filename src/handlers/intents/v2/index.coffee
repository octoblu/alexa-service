module.exports =
  default:               require('./handle-intent')
  'AMAZON.StopIntent':   require('../v1/handle-stop')
  'AMAZON.CancelIntent': require('../v1/handle-cancel')
