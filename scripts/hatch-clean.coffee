#!/usr/bin/env coffee

argv = require('optimist')
    .usage('''
           Clean the corresponding output when layout is changed
           Usage: $0 filename.md ...
           ''')
    .argv
files = argv._

if files.length is 0
    console.log '\tNothing cleaned.'
    process.exit(0)

async = require 'async'
path =require 'path'
Hatch = require('./../lib/core').Hatch

hatch = new Hatch()

if files.length > 5
    shell = require 'shelljs'

    console.log '\tToo many layouts changed, clean all outputs.'
    shell.rm '-rf', hatch.config.out
    process.exit(0)

hatch.clean files, (err, count) ->
    count = 'all' if count is 0
    console.log "\t#{count} docs cleaned."
    hatch.terminate()
