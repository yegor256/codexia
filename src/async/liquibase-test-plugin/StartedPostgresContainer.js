'usee strict'

const { AsyncObject } = require('@cuties/cutie')
const { exec } = require('child_process')

class StartedPostgresContainer extends AsyncObject {
  constructor (postgresOptions) {
    super(postgresOptions)
  }

  asyncCall () {
    return (postgresOptions, callback) => {
      this.name = postgresOptions.containerName || 'liquibase-plugin-container'
      exec(
        `docker run --rm --name ${postgresOptions.containerName || 'liquibase-plugin-container'} \
           -e POSTGRES_PASSWORD=${postgresOptions.password || ''} \
           -e POSTGRES_USER=${postgresOptions.user || 'postgres'} \
           -e POSTGRES_DB=${postgresOptions.db || 'postgres'} \
           -d -p ${postgresOptions.port || '5432:5432'} \
           -v ${postgresOptions.volumes || '$HOME/docker/volumes/postgres'}:/var/lib/postgresql/data postgres`,
        callback
      )
    }
  }

  onResult (stdout) {
    console.log('Postgres is started')
    console.log(stdout)
    return this.name
  }
}

module.exports = StartedPostgresContainer
