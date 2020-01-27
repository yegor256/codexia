'use strict'

const { as } = require('@cuties/cutie')
const { Assertion } = require('@cuties/assert')
const { IsString } = require('@cuties/is')
const OptionsForPostgresContainer = require('./../../../src/async/dockerized-postgres/OptionsForPostgresContainer')
const StartedPostgresContainer = require('./../../../src/async/dockerized-postgres/StartedPostgresContainer')
const KilledPostgresContainer = require('./../../../src/async/dockerized-postgres/KilledPostgresContainer')
const IpAddressOfPostgresContainer = require('./../../../src/async/dockerized-postgres/IpAddressOfPostgresContainer')
const uuidv4 = require('uuid/v4')

const postgresContainerName = uuidv4()
const db = uuidv4()
const user = uuidv4()
const password = uuidv4()

new StartedPostgresContainer(
  new OptionsForPostgresContainer(
    postgresContainerName,
    db,
    user,
    password
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
