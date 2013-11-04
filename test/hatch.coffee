# the hatch configuration file

hatchConfig =
    database:
        url: 'localhost/hatch_test'
        collection: 'documents'

    layoutData:
        site:
            # default url of the site
            url: 'http://hatch-jade-example.com'
            # default time of the site
            title: 'Example website build with hatch'
            # The website description (for SEO)
            description: """
                         This website is just a example site for explaining how hatch works。
                         """

            # The website keywords (for SEO) separated by commas
            keywords: """
                      hatch, nodejs, static site generator
            """

            # the meta of the website
            meta: [

            ]

            styles: [
                "/assets/css/app.min.css"
            ]

            scripts: [
                "/assets/js/jquery.min.js",
                "/assets/js/bootstrap.min.js",
                "/assets/js/app.min.js"
            ]

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


module.exports = hatchConfig



