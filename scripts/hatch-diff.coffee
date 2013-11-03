#!/usr/bin/env coffee
diffPath = require('./../lib/diff').diffPath

argv = require('optimist')
    .usage('''
           Compare two folders
           Usage: $0 [--ext html] src_dir dst_dir
           ''')
    .demand(2)
    .alias('e', 'ext')
    .describe('e', 'destination file extention')
    .argv


[src, dst] = argv._
ext = argv.e

diffPath src, dst, ext, (err, data) ->
    for item in data
        console.log item

