class Datastore
  get: (key, callback=->) =>
    callback null,
      'some-trigger-uuid':
        type: 'nanocyte-node-trigger'
        linkedTo: ['some-debug-uuid']
      'some-debug-uuid':
        type: 'nanocyte-node-debug'
        linkedTo: ['meshblu-output']
      'meshblu-output':
        type: 'meshblu-output'
        linkedTo: []

module.exports = Datastore
