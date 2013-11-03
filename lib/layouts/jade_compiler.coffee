jade = require 'jade'
fs = require 'fs'
path = require 'path'

compile = (filename) ->
    content = fs.readFileSync filename
    options =
        filename: filename
        pretty: true

    jade.compile content, options

module.exports.compile = compile
