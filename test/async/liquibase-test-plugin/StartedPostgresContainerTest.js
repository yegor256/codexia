'use strict'

const { as } = require('@cuties/cutie')
const PulledPostgresByDocker = require('./../../../src/async/liquibase-test-plugin/PulledPostgresByDocker')
const StartedPostgresContainer = require('./../../../src/async/liquibase-test-plugin/StartedPostgresContainer')
const KilledPostgresContainer = require('./../../../src/async/liquibase-test-plugin/KilledPostgresContainer')
const { Assertion } = require('@cuties/assert')
const { IsString } = require('@cuties/is')

new PulledPostgresByDocker().after(
  new Assertion(
    new IsString(
      new StartedPostgresContainer({
        'containerName': 'testName1',
        'port': '5433:5433'
      }).as('PG_CONTAINER')
    )
  ).after(
    new KilledPostgresContainer(
      as('PG_CONTAINER')
    )
  )
).call()

new PulledPostgresByDocker().after(
  new Assertion(
    new IsString(
      new StartedPostgresContainer({}).as('PG_CONTAINER')
    )
  ).after(
    new KilledPostgresContainer(
      as('PG_CONTAINER')
    )
  )
).call()
