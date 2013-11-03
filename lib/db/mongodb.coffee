mongojs = require 'mongojs'
_ = require 'lodash'

client = null


class Adapater
    constructor: (config) ->
        @db = mongojs(config.url)
        @collection = @db.collection(config.collection)

    findTag: (tag, limit, cb) ->
        query = tags: tag
        if limit == 0
            @collection.find(query).sort(date: -1, cb)
        else
            @collection.find(query).sort(date: -1).limit(limit, cb)

    find: -> @collection.find.apply @collection, arguments

    findOne: -> @collection.findOne.apply @collection, arguments

    insert: -> @collection.insert.apply @collection, arguments

    update: -> @collection.update.apply @collection, arguments

    save: -> @collection.save.apply @collection, arguments

    close: -> @db.close()

module.exports.Adapter = Adapater