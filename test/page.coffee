vows    = require 'vows'
assert  = require 'assert'
phantom = require '../phantom'
express = require 'express'


describe = (name, bat) -> vows.describe(name).addBatch(bat).export(module)

# Make coffeescript not return anything
# This is needed because vows topics do different things if you have a return value
t = (fn) ->
  (args...) ->
    fn.apply this, args
    return

app = express.createServer()

app.get '/', (req, res) ->
  res.send """
    <html>
      <head>
        <title>Test page title</title>
        <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.6.4/jquery.min.js"></script>
      </head>
      <body>
        <div id="somediv">
          <div class="anotherdiv">Some page content</div>
        </div>
        <button class="clickme" style="position: absolute; top: 123px; left: 123px; width: 20px; height; 20px" onclick="window.i_got_clicked = true;" />
      </body>
    </html>
  """

app.listen 23765


describe "Pages"
  "A Phantom page":
    topic: t ->
      test = this
      phantom.create (p) ->
        p.createPage (page) ->
          test.callback null, page, p

    "can open a URL on localhost":
      topic: t (page) ->
        page.open "http://127.0.0.1:23765/", (status) =>
          @callback null, page, status

      "and succeed": (err, page, status) ->
        assert.equal status, "success"

      "and the page, once it loads,":
        topic: t (page) ->
          setTimeout =>
            @callback null, page
          , 1500

        "has a title":
          topic: t (page) ->
            page.evaluate (-> document.title), (title) => @callback null, title
          
          "which is correct": (title) ->
            assert.equal title, "Test page title"

        "can evaluate DOM nodes":
          topic: t (page) ->
            page.evaluate (-> document.getElementById('somediv')), (node) => @callback null, node

          "which match": (node) ->
            assert.equal node.tagName, 'DIV'
            assert.equal node.id, 'somediv'

        "can evaluate scripts defined in the header":
          topic: t (page) ->
            page.evaluate (-> $('#somediv').html()), (html) => @callback null, html              
          
          "which return the correct result": (html) ->
            html = html.replace(/\s\s+/g, "")
            assert.equal html, '<div class="anotherdiv">Some page content</div>'
        
    
        "can simulate clicks on page locations":
          topic: t (page) ->
            page.sendEvent 'click', 133, 133
            page.evaluate (-> window.i_got_clicked), (clicked) => @callback null, clicked

          "and have those clicks register": (clicked) ->
            assert.ok clicked

        "can register an onConsoleMessage handler":
          topic: t (page) ->
            test = this
            page.set 'onConsoleMessage', (msg) -> test.callback null, msg
            page.evaluate (-> console.log "Hello, world!")

          "which works correctly": (msg) ->
            assert.equal msg, "Hello, world!"

    
    teardown: (page, ph) ->
      ph.exit()
