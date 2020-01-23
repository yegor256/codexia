'usee strict'

const { AsyncObject } = require('@cuties/cutie')
const { exec } = require('child_process')

class StartedPostgresContainer extends AsyncObject {
  constructor (postgresOptions) {
    super(postgresOptions)
  }

  asyncCall () {
    return (postgresOptions, callback) => {
      this.name = postgresOptions.containerName || 'postgres-container'
      exec(
        `sudo docker run --rm --name ${postgresOptions.containerName || 'postgres-container'} \
           -e POSTGRES_PASSWORD=${postgresOptions.password || ''} \
           -e POSTGRES_USER=${postgresOptions.user || 'postgres'} \
           -e POSTGRES_DB=${postgresOptions.db || 'postgres'} \
           -p ${postgresOptions.port || '5432:5432'} \
           -d postgres`,
        callback
      )
    }
  }

  onResult (stdout) {
    console.log('Postgres is started')
    console.log(this.name)
    console.log(stdout)
    return this.name
  }
}

module.exports = StartedPostgresContainer
