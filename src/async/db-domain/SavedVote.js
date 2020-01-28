'use strict'

const { AsyncObject } = require('@cuties/cutie')

class SavedVote extends AsyncObject {
  constructor (pgClient, reviewId, userLogin, positive) {
    super(pgClient, reviewId, userLogin, positive)
  }

  asyncCall () {
    return (pgClient, reviewId, userLogin, positive, callback) => {
      pgClient.query(
        'INSERT INTO vote (review, "user", positive) VALUES ($1, $2, $3) RETURNING *',
        [ reviewId, userLogin, positive ],
        callback
      )
    }
  }

  onResult (result) {
    return result.rows[0]
  }
}

module.exports = SavedVote
