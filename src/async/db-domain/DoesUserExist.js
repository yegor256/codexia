'use strict'

const { AsyncObject } = require('@cuties/cutie')

class DoesUserExist extends AsyncObject {
  constructor (pgClient, login) {
    super(pgClient, login)
  }

  asyncCall () {
    return (pgClient, login, callback) => {
      pgClient.query(
        'SELECT * FROM "user" WHERE login = $1',
        [ login ],
        callback
      )
    }
  }

  onResult (result) {
    return result.rows.length > 0
  }
}

module.exports = DoesUserExist
