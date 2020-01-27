'use strict'

const { AsyncObject } = require('@cuties/cutie')

class OptionsForPostgresContainer extends AsyncObject {
  constructor (containerName, user, db, password) {
    super(containerName, user, db, password)
  }

  syncCall () {
    return (containerName, user, db, password) => {
      return {
        'containerName': containerName,
        'user': user,
        'db': db,
        'password': password
      }
    }
  }
}

module.exports = OptionsForPostgresContainer
