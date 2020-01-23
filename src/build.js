'use strict'

const { as } = require('@cuties/cutie')
const {
  ExecutedLint,
  ExecutedTestCoverageCheck,
  ExecutedTestCoverage
} = require('@cuties/wall')
const PulledPostgresByDocker = require('./async/liquibase-test-plugin/PulledPostgresByDocker')
const StartedPostgresContainer = require('./async/liquibase-test-plugin/StartedPostgresContainer')
const KilledPostgresContainer = require('./async/liquibase-test-plugin/KilledPostgresContainer')
const postgresOptionsForTests = {
  'containerName': 'codexia-posgres-test-container',
  'port': '5400:5400'
}

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
    new PulledPostgresByDocker().after(
      new StartedPostgresContainer(
        postgresOptionsForTests
      ).as('PG_CONTAINER').after(
        new KilledPostgresContainer(
          as('PG_CONTAINER')
        )
      )
    )
  )
).call()
