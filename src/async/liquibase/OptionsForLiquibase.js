'use strict'

const { AsyncObject } = require('@cuties/cutie')

class OptionsForLiquibase extends AsyncObject {
  constructor (liquibaseClasspath, postgresClasspath, changeLogFile, host, port, db, user, password) {
    super(liquibaseClasspath, postgresClasspath, changeLogFile, host, port, db, user, password)
  }

  syncCall () {
    return (liquibaseClasspath, postgresClasspath, changeLogFile, host, port, db, user, password) => {
      return {
        'liquibase': liquibaseClasspath,
        'classpath': postgresClasspath,
        'changeLogFile': changeLogFile,
        'url': `jdbc:postgresql://${host}:${port}/${db}`,
        'username': user,
        'password': password
      }
    }
  }
}

module.exports = OptionsForLiquibase
