'use strict'

const { as } = require('@cuties/cutie')
const {
  ExecutedLint,
  ExecutedTestCoverageCheck,
  ExecutedTestCoverage
} = require('@cuties/wall')
const { Logged } = require('@cuties/async')
const { WrittenFile } = require('@cuties/fs')
const { CreatedOptions } = require('@cuties/object')
const { StringifiedJSON } = require('@cuties/json')
const StartedPostgresContainer = require('./async/dockerized-postgres/StartedPostgresContainer')
const KilledPostgresContainer = require('./async/dockerized-postgres/KilledPostgresContainer')
const OptionsForPostgresContainer = require('./async/dockerized-postgres/OptionsForPostgresContainer')
const IpAddressOfPostgresContainer = require('./async/dockerized-postgres/IpAddressOfPostgresContainer')
const MappedPortOfPostgresContainer = require('./async/dockerized-postgres/MappedPortOfPostgresContainer')
const AppliedLiquibaseMigrations = require('./async/liquibase/AppliedLiquibaseMigrations')
const OptionsForLiquibase = require('./async/liquibase/OptionsForLiquibase')
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
  './src/events',
  './test/async'
).after(
  new StartedPostgresContainer(
    new OptionsForPostgresContainer(
      postgresContainerName, user, db, password
    )
  ).as('PG_CONTAINER').after(
    new IpAddressOfPostgresContainer(
      as('PG_CONTAINER')
    ).as('PG_HOST').after(
      new MappedPortOfPostgresContainer(
        as('PG_CONTAINER')
      ).as('PG_PORT').after(
        new Sleep(1000).after(
          new AppliedLiquibaseMigrations(
            liquibase,
            new OptionsForLiquibase(
              'node_modules/liquibase-deps/liquibase-core-3.5.3.jar',
              'node_modules/liquibase-deps/postgresql-9.4-1201.jdbc4.jar',
              'resources/liquibase/db.changelog.xml',
              as('PG_HOST'), as('PG_PORT'), db, user, password
            )
          ).after(
            new Logged(
              'liquibase migrations are applied'
            ).after(
              new WrittenFile(
                './target/postgres/config.json',
                new StringifiedJSON(
                  new CreatedOptions(
                    'host', as('PG_HOST'),
                    'port', as('PG_PORT'),
                    'database', db,
                    'user', user,
                    'password', password
                  )
                )
              ).after(
                new ExecutedTestCoverageCheck(
                  new ExecutedTestCoverage(process, './test.js'),
                  { 'lines': 100, 'functions': 100, 'branches': 100 }
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
  )
).call()
