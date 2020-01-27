'use strict'

const { as } = require('@cuties/cutie')
const { Assertion } = require('@cuties/assert')
const { IsString } = require('@cuties/is')
const OptionsForPostgresContainer = require('./../../../src/async/dockerized-postgres/OptionsForPostgresContainer')
const StartedPostgresContainer = require('./../../../src/async/dockerized-postgres/StartedPostgresContainer')
const KilledPostgresContainer = require('./../../../src/async/dockerized-postgres/KilledPostgresContainer')
const IpAddressOfPostgresContainer = require('./../../../src/async/dockerized-postgres/IpAddressOfPostgresContainer')
const uuidv4 = require('uuid/v4')

new StartedPostgresContainer(
  new OptionsForPostgresContainer(
    uuidv4(),
    uuidv4(),
    uuidv4(),
    uuidv4()
  )
).as('PG_CONTAINER').after(
  new Assertion(
    new IsString(
      new IpAddressOfPostgresContainer(
        as('PG_CONTAINER')
      )
    )
  ).after(
    new KilledPostgresContainer(
      as('PG_CONTAINER')
    )
  )
).call()
