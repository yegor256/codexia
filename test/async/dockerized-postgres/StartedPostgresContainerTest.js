'use strict'

const { as } = require('@cuties/cutie')
const PulledPostgresByDocker = require('./../../../src/async/dockerized-postgres/PulledPostgresByDocker')
const StartedPostgresContainer = require('./../../../src/async/dockerized-postgres/StartedPostgresContainer')
const KilledPostgresContainer = require('./../../../src/async/dockerized-postgres/KilledPostgresContainer')
const { Assertion } = require('@cuties/assert')
const { IsString } = require('@cuties/is')
const { CreatedOptions } = require('@cuties/object')
const FreeRandomPort = require('./../../../src/async/net/FreeRandomPort')
const uuidv4 = require('uuid/v4')

new PulledPostgresByDocker().after(
  new Assertion(
    new IsString(
      new StartedPostgresContainer(
        new CreatedOptions(
          'containerName', uuidv4(),
          'port', new FreeRandomPort()
        )
      ).as('PG_CONTAINER')
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
