fs = require 'fs'
file = require 'file'
path = require 'path'
async = require 'async'
_ = require 'lodash'


# params should contain src, dst and ext
diffPath = (src, dst, ext, callback) ->
    fileTimeDiff = (src_file, cb) ->
        old_ext = path.extname(src_file)
        dst_file = src_file.replace(src, dst)
        if ext
            dst_file = dst_file.replace(old_ext, ext)

        fs.stat src_file, (err, src_stat) ->
            return cb(err) if err

            fs.exists dst_file, (exists) ->
                return cb null, src_file if not exists

                fs.stat dst_file, (err, dst_stat) ->
                    cb(err) if err

                    if src_stat.mtime > dst_stat.mtime
                        cb null, src_file
                    else
                        cb null, null


    file.walk src, (err, dirPath, dirs, files) ->
        async.map files, fileTimeDiff, (err, results) ->
            callback err, _.compact(results)

module.exports.diffPath = diffPath