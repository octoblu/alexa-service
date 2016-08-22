module.exports = {
  Trigger: require('./handle-trigger')
  ListTriggers: require('./handle-list-triggers')
  'AMAZON.HelpIntent': require('./handle-help')
  'AMAZON.StopIntent': require('./handle-stop')
  'AMAZON.CancelIntent': require('./handle-cancel')
}
