'use strict'

const { AsyncObject } = require('@cuties/cutie')

class SavedReview extends AsyncObject {
  constructor (pgClient, projectId, authorLogin, text) {
    super(pgClient, projectId, authorLogin, text)
  }

  asyncCall () {
    return (pgClient, projectId, authorLogin, text, callback) => {
      pgClient.query(
        'INSERT INTO review (project, author, text) VALUES ($1, $2, $3) RETURNING *',
        [ projectId, authorLogin, text ],
        callback
      )
    }
  }

  onResult (result) {
    return result.rows[0]
  }
}

module.exports = SavedReview
