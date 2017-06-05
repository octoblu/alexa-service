module.exports = {
  LaunchRequest:         require './handle-launch-request'
  IntentRequest:         require '../v1/handle-intent-request'
  SessionEndedRequest:   require '../v1/handle-session-ended-request'
}
