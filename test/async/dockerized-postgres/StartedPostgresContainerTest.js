'use strict'

const { as } = require('@cuties/cutie')
const PulledPostgresByDocker = require('./../../../src/async/dockerized-postgres/PulledPostgresByDocker')
const StartedPostgresContainer = require('./../../../src/async/dockerized-postgres/StartedPostgresContainer')
const KilledPostgresContainer = require('./../../../src/async/dockerized-postgres/KilledPostgresContainer')
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
