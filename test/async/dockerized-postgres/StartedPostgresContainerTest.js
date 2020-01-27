'use strict'

const { as } = require('@cuties/cutie')
const { Assertion } = require('@cuties/assert')
const { IsObject } = require('@cuties/is')
const OptionsForPostgresContainer = require('./../../../src/async/dockerized-postgres/OptionsForPostgresContainer')
const StartedPostgresContainer = require('./../../../src/async/dockerized-postgres/StartedPostgresContainer')
const KilledPostgresContainer = require('./../../../src/async/dockerized-postgres/KilledPostgresContainer')
const uuidv4 = require('uuid/v4')

const postgresContainerName = uuidv4()
const db = uuidv4()
const user = uuidv4()
const password = uuidv4()

new Assertion(
  new IsObject(
    new StartedPostgresContainer(
      new OptionsForPostgresContainer(
        postgresContainerName,
        db,
        user,
        password
      )
    ).as('PG_CONTAINER')
  )
).after(
  new KilledPostgresContainer(
    as('PG_CONTAINER')
  )
).call()

new Assertion(
  new IsObject(
    new StartedPostgresContainer({}).as('PG_CONTAINER')
  )
).after(
  new KilledPostgresContainer(
    as('PG_CONTAINER')
  )
).call()
