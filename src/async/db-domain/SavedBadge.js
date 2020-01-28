'use strict'

const { AsyncObject } = require('@cuties/cutie')

class SavedBadge extends AsyncObject {
  constructor (pgClient, projectId, text) {
    super(pgClient, projectId, text)
  }

  asyncCall () {
    return (pgClient, projectId, text, callback) => {
      pgClient.query(
        'INSERT INTO badge (project, text) VALUES ($1, $2) RETURNING *',
        [ projectId, text ],
        callback
      )
    }
  }

  onResult (result) {
    return result.rows[0]
  }
}

module.exports = SavedBadge
