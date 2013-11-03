_ = require 'lodash'
yaml = require 'js-yaml'
fs = require 'fs'
path = require 'path'
marked = require 'marked'
shell = require 'shelljs'
Adapter = require('./db/index').MongoAdapter

compilers = []
compilers['.jade'] = require('./layouts/jade_compiler').compile


# setting highlight will make performance 3x worse. So disable it.
# we can enable syntax highlight in client side with lightlight.js.
#hljs = require 'highlight.js'
#marked.setOptions
#    highlight: (code) ->
#        hljs.highlightAuto(code).value

conventions =
    # the name of source directory
    src: 'src'

    # the name of raw directory
    raw: 'raw'

    # the name of build directory
    out: 'out'

    # the name of contents directory
    contents: 'contents'

    # the name of layouts directory
    layouts: 'layouts'

    # the name of template directory
    templates: 'templates'

    # metadata notation in the document
    regexMetadata: /^-{3,}\s([\s\S]*?)-{3,}(\s[\s\S]*|\s?)$/

    # teaser notation in the document
    regexTeaser: /<!--\s*teaser\s*-->\s*([\s\S]*?)\s*<!--\s*teaser\s*-->/i

    # page notation in the document
    regexPager: /<!--\s*page\s*-->/

    getTemplate: (name) ->
        "#{@src}/#{@templates}/#{name}"

    getLayout: (name) ->
        "#{@src}/#{@layouts}/#{name}"

    getDocument: (name) ->
        "#{@src}/#{@documents}/#{name}"

    getRaw: (name) ->
        "#{@raw}/#{name}"

    getBuild: (name) ->
        "#{@build}/#{name}"

defaultConfig =
    database:
        url: 'localhost/hatch'
        collection: 'documents'

    # default meta data of a document
    metadata:
        layout: '',
        createdAt: null,
        updatedAt: null,
        tags: [],
        ignored: false,
        comments: true,
        cover: '',
        src: '',
        contents: [],
        title: '',
        content: '',
        teaser: '',

    layoutData:
        site:
            # default url of the site
            url: ''

            # default time of the site
            title: ''

            # The website description (for SEO)
            description: ''

            # The website keywords (for SEO) separated by commas
            keywords: ''

            # the meta of the website
            meta: []

            # the styles of the website
            styles: []

            # the scripts of the website
            scripts: []

        # Helper functions

        getTitle: ->
            if @document.title
                "#{@document.title} | #{@site.title}"
            else
                @site.title

        getDescription: ->
            @document.description or @site.description

        getKeywords: ->
            @site.keywords.concat(@document.keywords or []).join(', ')

        getRelated: (tags)->
            @adapter.findTag tags: $in: tags, 0, (err, docs) ->
                



# helpers
getTarget: (filename, src, dst, ext='.html') ->
    if ext
        filename.replace(src, dst).replace(path.extname(filename), ext)
    else
        filename.replace(src, dst)

class Hatch
    constructor: () ->
        @config = {}
        _.extend @config, defaultConfig
        try
            config = require('./../../hatch.coffee')
        catch err
            config = {}
        _.extend @config, config
        _.extend @config, conventions
        @config.adapter = @config.layoutData.adapter = @adapter = new Adapter(@config.database)

    # parse the file and update/insert it into database
    # the filename should be unique.
    upsert: (filename, cb) ->
        self = @
        @adapter.find(src: filename).limit 1, (err, docs) ->
            return cb(err) if err

            self.parseDocument filename, (err, data) ->
                return cb(err) if err

                if docs.length is 1
                    doc = docs[0]
                    # update the document with latest file content, notify callback about what changed
                    changed =
                        tags: false
                        createdAt: false
                        ignored: false

                    changed.tags = true if not _.isEqual(doc.tags, data.tags)
                    changed.createdAt = true if doc.createdAt isnt data.createdAt
                    changed.ignored = true if doc.ignored isnt data.ignored
                    _.extend doc, data
                    self.adapter.save doc, (err) ->
                        process.stdout.write('u')
                        cb err, {type:'update', data: changed}
                else
                    self.adapter.save data, (err) ->
                        process.stdout.write('c')
                        cb(err, {type: 'insert', data: null})


    # parse a document to a javascript object, for callback cb to process
    parseDocument: (filename, cb) ->
        self = @
        options =
            encoding: 'utf-8'
        fs.readFile filename, options, (err, text) ->
            return cb(err) if err
            mdata = {}
            _.extend mdata, self.config.metadata
            fs.stat filename, (err, stat) ->
                return cb(err) if err
                mdata['updatedAt'] = mdata['createdAt'] = stat.mtime
                if text[0...3] is '---'
                    result = text.match self.config.regexMetadata
                    if result?.length is 3
                        try
                            data = yaml.safeLoad(result[1])
                            data.src = filename
                            content = result[2]
                            data.contents = _.map content.split(self.config.regexPager), (s) -> marked(s)
                            result = content.match self.config.regexTeaser
                            data.teaser = result[1] if result?.length is 2
                            data.createdAt = data.date
                            delete data.date
                            _.extend mdata, data
                            cb null, mdata
                        catch err
                            cb err
                    else
                        cb null, null
                else
                    cb null, null

    # pre-compile all the layouts so that later we could use it directly
    compileLayouts: (layout_dir) ->
        @layouts = []
        files = fs.readdirSync path.join layout_dir

        for file in files
            try
                @layouts[file] = compilers[path.extname(file)]?("#{layout_dir}/#{file}")
            catch err
                console.error "Cannot parse layout: #{layout_dir}/#{file}"

    # generate the output based on the src file (we will leverage the parsed result in database).
    generate: (src, cb) ->
        self = @
        dst = src.replace(@config.src, @config.out).replace(path.extname(src), '.html')

        @adapter.findOne src: src, (err, doc) ->
            return cb(err) if err

            if doc
                locals = {document: doc}
                _.extend locals, self.config.layoutData
                for own key, value of locals
                    if _.isFunction value
                        locals[key] = value.bind(locals)
                html = self.layouts[doc.layout] locals
                fs.writeFile dst, html, (err) ->
                    cb err, dst
            else
                cb null, null

    # clean the corresponding outputs when layout changes.
    clean: (filenames, cb) ->
        self = @
        layouts = _.map filenames, (f) -> path.basename(f)
        @adapter.find layout: $in: layouts, (err, docs) ->
            return cb(err) if err

            if docs.length is 0
                # we didn't find the layout used by anyone, could be a partial
                # so we clean all files for safe
                shell.rm '-rf', self.config.out
                cb null, 0
            else
                # remove the file
                filenames = _.pluck docs, 'src'
                filenames = _.map filenames, (f) ->
                    f.replace(self.config.src, self.config.out).replace(path.extname(f), '.html')
                shell.rm '-f', filenames
                cb null, docs.length


    terminate: ->
        @adapter.close()

module.exports.Hatch = Hatch