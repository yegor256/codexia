'use strict'

const { AsyncObject } = require('@cuties/cutie')

class OptionsForPostgresContainer extends AsyncObject {
  constructor (containerName, port, user, db, password) {
    super(containerName, port, user, db, password)
  }

  syncCall () {
    return (containerName, port, user, db, password) => {
      return {
        'containerName': containerName,
        'port': `${port}:5432`,
        'user': user,
        'db': db,
        'password': password
      }
    }
  }
}

module.exports = OptionsForPostgresContainer
