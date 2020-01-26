'use strict'

const { ReadDataByPath } = require('@cuties/fs')
const { ParsedJSON, Value } = require('@cuties/json')
const PulledPostgresByDocker = require('./async/dockerized-postgres/PulledPostgresByDocker')
const StartedPostgresContainer = require('./async/dockerized-postgres/StartedPostgresContainer')

new PulledPostgresByDocker().after(
  new StartedPostgresContainer(
    new Value(
      new ParsedJSON(
        new ReadDataByPath(
          './resources/config.envs.json',
          { 'encoding': 'utf8' }
        )
      ),
      'local.dockerizedPostgres'
    )
  )
).call()
