'usee strict'

const { AsyncObject } = require('@cuties/cutie')

class ConnectedPostgresClient extends AsyncObject {
  constructor (options, ClientModule) {
    super(options, ClientModule)
  }

  syncCall () {
    return (options, ClientModule) => {
      const client = new ClientModule(options)
      client.connect()
      return client
    }
  }
}

module.exports = ConnectedPostgresClient
