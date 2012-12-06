fs    = require('fs')
jsdom = require('jsdom')

helper =
  setupWindow: () ->
    scripts = ['flamsteed']
    jsdom.env({
      html:    '<html><head></head><body></body></html>'
      scripts: scripts.map (file) ->  __dirname + '/../../../lib/javascripts/' + file + ".js"
      src:     ''
      done:    (errors, newWindow) ->
        global.window = newWindow # must be last as it releases
        # flow control to jasmine
    })

    beforeEach(() ->
      waitsFor(() ->
        return typeof window isnt "undefined"
      )
      runs(() ->
        throw new Error("window.document was not set") unless window.document
      )
    )

helper.setupWindow()

module.exports = helper