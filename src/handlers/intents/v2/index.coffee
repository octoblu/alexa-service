module.exports = {
  default:               require('./handle-trigger')
  Trigger:               require('./handle-trigger')
  ListTriggers:          require('./handle-list-triggers')
  'AMAZON.HelpIntent':   require('../v1/handle-help')
  'AMAZON.StopIntent':   require('../v1/handle-stop')
  'AMAZON.CancelIntent': require('../v1/handle-cancel')
}
