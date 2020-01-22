'use strict'

const {
  ExecutedLint,
  ExecutedTestCoverageCheck,
  ExecutedTestCoverage
} = require('@cuties/wall')

new ExecutedLint(
  process,
  './src/app.js',
  './src/build.js',
  './src/async',
  './src/endpoints',
  './src/events'
).after(
  new ExecutedTestCoverageCheck(
    new ExecutedTestCoverage(process, './test.js'),
    { 'lines': 100, 'functions': 100, 'branches': 100 }
  )
).call()
