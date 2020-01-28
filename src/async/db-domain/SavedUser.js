'use strict'

const { AsyncObject } = require('@cuties/cutie')

class SavedUser extends AsyncObject {
  constructor (pgClient, login, avatarUrl) {
    super(pgClient, login, avatarUrl)
  }

  asyncCall () {
    return (pgClient, login, avatarUrl, callback) => {
      pgClient.query(
        'INSERT INTO "user" (login, avatar_url) VALUES ($1, $2) RETURNING *',
        [ login, avatarUrl ],
        callback
      )
    }
  }

  onResult (result) {
    return result.rows[0]
  }
}

module.exports = SavedUser
