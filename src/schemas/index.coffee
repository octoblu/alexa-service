module.exports =
  schemas:
    configure:
      Default: require('./configure/default.cson')
    form:
      configure:
        Default: require('./configure/default-form.cson')
      message:
        EndSession: require('./message/end-session-form.cson')
        Reprompt: require('./message/reprompt-form.cson')
        Say: require('./message/say-form.cson')
        SimpleCard: require('./message/simple-card-form.cson')
        StandardCard: require('./message/standard-card-form.cson')
    message:
      EndSession: require('./message/end-session.cson')
      Reprompt: require('./message/reprompt.cson')
      Say: require('./message/say.cson')
      SimpleCard: require('./message/simple-card.cson')
      StandardCard: require('./message/standard-card.cson')
