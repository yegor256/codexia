'use strict'

const { as } = require('@cuties/cutie')
const { ReadDataByPath } = require('@cuties/fs')
const { ParsedJSON, Value } = require('@cuties/json')
const { Logged } = require('@cuties/async')
const StartedPostgresContainer = require('./async/dockerized-postgres/StartedPostgresContainer')
const IpAddressOfPostgresContainer = require('./async/dockerized-postgres/IpAddressOfPostgresContainer')
const MappedPortOfPostgresContainer = require('./async/dockerized-postgres/MappedPortOfPostgresContainer')

new StartedPostgresContainer(
  new Value(
    new ParsedJSON(
      new ReadDataByPath(
        './resources/local.json',
        { 'encoding': 'utf8' }
      )
    ),
    'dockerizedPostgres'
  )
).as('PG_CONTAINER').after(
  new Logged(
    'host \n', new IpAddressOfPostgresContainer(as('PG_CONTAINER')),
    'port \n', new MappedPortOfPostgresContainer(as('PG_CONTAINER'))
  )
).call()
