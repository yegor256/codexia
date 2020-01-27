'use strict'

const { as } = require('@cuties/cutie')
const {
  ExecutedLint,
  ExecutedTestCoverageCheck,
  ExecutedTestCoverage
} = require('@cuties/wall')
const { Logged } = require('@cuties/async')
const PulledPostgresByDocker = require('./async/dockerized-postgres/PulledPostgresByDocker')
const StartedPostgresContainer = require('./async/dockerized-postgres/StartedPostgresContainer')
const KilledPostgresContainer = require('./async/dockerized-postgres/KilledPostgresContainer')
const OptionsForPostgresContainer = require('./async/dockerized-postgres/OptionsForPostgresContainer')
const AppliedLiquibaseMigrations = require('./async/liquibase/AppliedLiquibaseMigrations')
const OptionsForLiquibase = require('./async/liquibase/OptionsForLiquibase')
const FreeRandomPort = require('./async/net/FreeRandomPort')
const Sleep = require('./async/process/Sleep')
const liquibase = require('liquibase')
const uuidv4 = require('uuid/v4')

const postgresContainerName = uuidv4()
const db = uuidv4()
const user = uuidv4()
const password = uuidv4()

new ExecutedLint(
  process,
  './src/app.js',
  './src/build.js',
  './src/async',
  './src/endpoints',
  './src/events'
).after(
  new ExecutedTestCoverageCheck(
    new ExecutedTestCoverage(process, './test.js'),
    { 'lines': 100, 'functions': 100, 'branches': 100 }
  ).after(
    new FreeRandomPort(5000, 6000).as('RANDOM_PORT').after(
      new PulledPostgresByDocker().after(
        new StartedPostgresContainer(
          new OptionsForPostgresContainer(
            postgresContainerName, as('RANDOM_PORT'), user, db, password
          )
        ).as('PG_CONTAINER').after(
          new Sleep(2000).after(
            new AppliedLiquibaseMigrations(
              liquibase,
              new OptionsForLiquibase(
                'node_modules/liquibase-deps/liquibase-core-3.5.3.jar',
                'node_modules/liquibase-deps/postgresql-9.4-1201.jdbc4.jar',
                'resources/liquibase/db.changelog.xml',
                '0.0.0.0', as('RANDOM_PORT'), db, user, password
              )
            ).after(
              new Logged(
                'liquibase migrations are applied'
              ).after(
                new KilledPostgresContainer(
                  as('PG_CONTAINER')
                )
              )
            )
          )
        )
      )
    )
  )
).call()
