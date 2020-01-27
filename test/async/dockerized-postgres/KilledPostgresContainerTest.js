'use strict'

const { as } = require('@cuties/cutie')
const { StrictEqualAssertion } = require('@cuties/assert')
const { IsString } = require('@cuties/is')
const { CreatedOptions } = require('@cuties/object')
const PulledPostgresByDocker = require('./../../../src/async/dockerized-postgres/PulledPostgresByDocker')
const StartedPostgresContainer = require('./../../../src/async/dockerized-postgres/StartedPostgresContainer')
const KilledPostgresContainer = require('./../../../src/async/dockerized-postgres/KilledPostgresContainer')
const FreeRandomPort = require('./../../../src/async/net/FreeRandomPort')
const uuidv4 = require('uuid/v4')

new PulledPostgresByDocker().after(
  new StartedPostgresContainer(
    new CreatedOptions(
      'containerName', uuidv4(),
      'port', new FreeRandomPort()
    )
  ).as('PG_CONTAINER').after(
    new StrictEqualAssertion(
      new KilledPostgresContainer(
        as('PG_CONTAINER')
      ), 0
    )
  )
).call()

new PulledPostgresByDocker().after(
  new StartedPostgresContainer(
    new CreatedOptions(
      'containerName', uuidv4(),
      'port', new FreeRandomPort()
    )
  ).as('PG_CONTAINER').after(
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
