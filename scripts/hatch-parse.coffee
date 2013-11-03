#!/usr/bin/env coffee

argv = require('optimist')
    .usage('''
           Pre generate the document into database
           Usage: $0 [-o filename.html] filename.md
           ''')
    .alias('o', 'output')
    .describe('o', 'output filename')
    .argv


files = argv._

if files.length is 0
    console.log '\tNothing changed.'
    process.exit(0)

async = require 'async'
Hatch = require('./../lib/core').Hatch

hatch = new Hatch()
async.map files, hatch.upsert.bind(hatch), (err, data) ->
    console.log "\t#{data.length} docs parsed."
    hatch.terminate()

