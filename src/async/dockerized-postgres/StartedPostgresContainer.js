'usee strict'

const { AsyncObject } = require('@cuties/cutie')
const { GenericContainer } = require('testcontainers')
const promiseToCallback = require('promise-to-callback')

class StartedPostgresContainer extends AsyncObject {
  constructor (postgresOptions) {
    super(postgresOptions)
  }

  asyncCall () {
    return (postgresOptions, callback) => {
      promiseToCallback(
        new GenericContainer('postgres')
          .withName(postgresOptions.containerName, 'postgres-container')
          .withEnv('POSTGRES_PASSWORD', postgresOptions.password || '')
          .withEnv('POSTGRES_USER', postgresOptions.user || 'postgres')
          .withEnv('POSTGRES_DB', postgresOptions.db || 'postgres')
          .withExposedPorts(5432)
          .start()
      )(callback)
    }
  }
}

module.exports = StartedPostgresContainer
