#!/usr/bin/env coffee

argv = require('optimist')
        .usage('''
           Pre generate the document into database
           Usage: $0 filename.md ...
           ''')
    .argv
files = argv._

if files.length is 0
    console.log '\tNothing changed.'
    process.exit(0)

async = require 'async'
path =require 'path'
_ = require 'lodash'
Hatch = require('./../lib/core').Hatch

hatch = new Hatch()
hatch.compileLayouts(path.join process.cwd(), hatch.config.src, hatch.config.layouts)


async.map files, hatch.generate.bind(hatch), (err, data) ->
    data = _.compact data
    console.log "\t#{data.length} docs generated."
    hatch.terminate()
