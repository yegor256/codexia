'use strict'

const { as } = require('@cuties/cutie')
const { Backend, RestApi, ServingFilesEndpoint } = require('@cuties/rest')
const { ReadDataByPath } = require('@cuties/fs')
const { ParsedJSON, Value } = require('@cuties/json')
const { ObjectWithValue } = require('@cuties/object')
const { Logged } = require('@cuties/async')
const AppliedLiquibaseMigrations = require('./async/liquibase/AppliedLiquibaseMigrations')
const liquibase = require('liquibase')

const env = process.env.NODE_ENV || 'local'

new ParsedJSON(
  new ReadDataByPath(
    `./resources/${env}.json`,
    { 'encoding': 'utf8' }
  )
).as('ENV_CONFIG').after(
  new AppliedLiquibaseMigrations(
    liquibase,
    new ObjectWithValue(
      new ObjectWithValue(
        new ObjectWithValue(
          new Value(
            as('ENV_CONFIG'),
            'liquibase'
          ),
          'liquibase', 'node_modules/liquibase-deps/liquibase-core-3.5.3.jar'
        ),
        'classpath', 'node_modules/liquibase-deps/postgresql-9.4-1201.jdbc4.jar'
      ),
      'changeLogFile', 'resources/liquibase/db.changelog.xml'
    )
  ).after(
    new Logged(
      'liquibase migrations are applied'
    )
  )
).call()
