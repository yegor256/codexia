'use strict'

const { as } = require('@cuties/cutie')
const PulledPostgresByDocker = require('./../../../src/async/liquibase-test-plugin/PulledPostgresByDocker')
const StartedPostgresContainer = require('./../../../src/async/liquibase-test-plugin/StartedPostgresContainer')
const KilledPostgresContainer = require('./../../../src/async/liquibase-test-plugin/KilledPostgresContainer')
const { StrictEqualAssertion } = require('@cuties/assert')
const { IsString } = require('@cuties/is')

new PulledPostgresByDocker().after(
  new StartedPostgresContainer({
    'containerName': 'testName2',
    'port': '5434:5434'
  }).as('PG_CONTAINER').after(
    new StrictEqualAssertion(
      new KilledPostgresContainer(
        as('PG_CONTAINER')
      ), 0
    )
  )
).call()

new PulledPostgresByDocker().after(
  new StartedPostgresContainer({
    'containerName': 'testName3',
    'port': '5435:5435'
  }).as('PG_CONTAINER').after(
    new StrictEqualAssertion(
      new KilledPostgresContainer(
        as('PG_CONTAINER')
      ), 0
    ).after(
      new StrictEqualAssertion(
        new KilledPostgresContainer(
          as('PG_CONTAINER')
        ), 0
      )
    )
  )
).call()
