'use strict'

const {
  ExecutedLint
} = require('@cuties/wall')

new ExecutedLint(
  process,
  './src/app.js',
  './src/build.js',
  './src/async',
  './src/endpoints',
  './src/events'
).call()
