## Intent Schema

```json
{
  "intents": [
    {
      "intent": "Trigger",
      "slots": [
        {
          "name": "Name",
          "type": "TRIGGER"
        }
      ]
    },
    {
      "intent": "AMAZON.HelpIntent"
    },
    {
      "intent": "ListTriggers"
    }
  ]
}
```

## Custom Slot Types:

### `TRIGGER`

* tasks
* notifications
* podio notifications
* meetings
* create meeting

## Sample Utterances

* Trigger {Name}
* Trigger the {Name}
* Trigger a {Name}
* Trigger get {Name}
* Trigger get a {Name}
* Trigger get the {Name}
* Trigger list {Name}
* Trigger list a {Name}
* Trigger list the {Name}
* Trigger set {Name}
* Trigger set a {Name}
* Trigger set the {Name}
* Trigger do {Name}
* Trigger do a {Name}
* Trigger do the {Name}
* Trigger trigger {Name}
* Trigger trigger a {Name}
* Trigger trigger the {Name}
* Trigger my {Name}
* Trigger get my {Name}
* Trigger list my {Name}
* Trigger set my {Name}
* Trigger do my {Name}
* Trigger trigger my {Name}
* ListTriggers what are my triggers
* ListTriggers what can I do
* ListTriggers list my triggers
* ListTriggers tell me my triggers

### Example commands

* Alexa ask Citrix to list my tasks
* Alexa ask Citrix to list my meetings
* Alexa ask Citrix to create meeting
* Alexa ask Citrix to get my notifications
* Alexa ask Citrix what can I do
* Alexa ask Citrix help
