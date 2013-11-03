#!/usr/bin/env coffee

argv = require('optimist')
    .usage('''
           Pre generate the document into database
           Usage: $0 filename.md
           ''')
    .alias('o', 'output')
    .argv

console.log argv

