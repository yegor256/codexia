'use strict'

const { as } = require('@cuties/cutie')
const OptionsForLiquibase = require('./../../../src/async/liquibase/OptionsForLiquibase')
const { DeepStrictEqualAssertion } = require('@cuties/assert')

new DeepStrictEqualAssertion(
  new OptionsForLiquibase(
    'liquibaseClasspath',
    'postgresClasspath',
    'changeLogFile',
    'host',
    'port',
    'db',
    'user',
    'password'
  ),
  {
    'liquibase': 'liquibaseClasspath',
    'classpath': 'postgresClasspath',
    'changeLogFile': 'changeLogFile',
    'url': 'jdbc:postgresql://host:port/db',
    'username': 'user',
    'password': 'password'
  }
).call()
