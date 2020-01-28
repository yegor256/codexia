'use strict'

const { AsyncObject } = require('@cuties/cutie')

class SavedProject extends AsyncObject {
  constructor (pgClient, submitterLogin, coordinates, platform = 'github') {
    super(pgClient, submitterLogin, coordinates, platform)
  }

  asyncCall () {
    return (pgClient, submitterLogin, coordinates, platform, callback) => {
      pgClient.query(
        'INSERT INTO project (submitter, coordinates, platform) VALUES ($1, $2, $3) RETURNING *',
        [ submitterLogin, coordinates, platform ],
        callback
      )
    }
  }

  onResult (result) {
    return result.rows[0]
  }
}

module.exports = SavedProject
