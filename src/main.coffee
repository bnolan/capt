fs = require('fs')
sys = require('sys')
Path = require("path")

root = __dirname + "/../"
server = require("#{root}/lib/router").getServer()
request = require("#{root}/lib/request")
_ = require("#{root}/lib/underscore")
yaml = require("#{root}/lib/yaml")

String.prototype.capitalize = ->
  this.charAt(0).toUpperCase() + this.substring(1).toLowerCase()

OptionParser = require("#{root}/lib/parseopt").OptionParser
parser = new OptionParser {
  minargs : 1
  maxargs : 10
}
data = parser.parse()

#
# Raise an error
#
raise = (error) ->
  sys.puts error
  process.exit()

#
# Load the project info from the current directory
#
class Project
  constructor: (cwd) ->
    @cwd = cwd

  name : ->
    @cwd.replace(/.+\//,'')

  language : ->
    'coffee' # or 'js'
    
  configPath : ->
    Path.join(@cwd, "config.yml")
    
  yaml : ->
    yaml.eval(fs.readFileSync(@configPath()))
    
  scriptIncludes : ->
    for pathspec in yaml.javascripts
      
    fs.readdirSync
    
  styleIncludes : ->
    
    
currentProject ||= new Project(process.cwd())

#
# Start the server
#  
if data.arguments[0] == "server"
  project = currentProject()

  server.get "/", (req, res, match) ->
    "<html><head></head><body>Hello world!</body></html>"

  server.get "/test/", (req, res) ->
    ejs = fs.readFileSync("#{root}/templates/html/runner.html") + ""
    sys.puts(typeof ejs)
    _.template(ejs, { project : project })
    # 
    # "<html><head></head><body>Hello world!</body></html>"
    
  server.get new RegExp("^/app/$"), (req, res, match) ->
    "Hello #{match}!"

  server.listen(3000)
  

#
# New project
#
if data.arguments[0] == "new"
  project = data.arguments[1] or raise("Must supply a name for new project.")

  sys.puts " * Creating folders"

  dirs = ["", "app", "app/views", "app/views/jst", "app/controllers", "app/models", "config", "lib", "public", "public/stylesheets", "test", "test/controllers", "test/views", "test/models", "test/fixtures"]
  
  for dir in dirs
    fs.mkdirSync "#{project}/#{dir}", 0755

  sys.puts " * Downloading libraries"

  libs = {
    "lib/jquery.js" : "http://code.jquery.com/jquery-1.4.4.js", 
    "lib/underscore.js" : "http://documentcloud.github.com/underscore/underscore.js"
    "lib/backbone.js" : "http://documentcloud.github.com/backbone/backbone.js"
    "test/qunit.js" : "http://github.com/jquery/qunit/raw/master/qunit/qunit.js"
    "test/qunit.css" : "http://github.com/jquery/qunit/raw/master/qunit/qunit.css"
  }
  
  downloadLibrary = (path, lib) ->
    request { uri : lib }, (error, response, body) ->
      if (!error && response.statusCode == 200)
        fs.writeFileSync("#{project}/#{path}", body)

  for path, lib of libs
    downloadLibrary(path, lib)
    
  # sys.puts "Done.\n"

#
# Generate model
#

if data.arguments[0] == "generate" and data.arguments[1] == "model"
  project = currentProject()

  name = data.arguments[2] or raise("Must supply a name for the model")

  files = {
    "app/models/#{name}.#{project.language}" : "
class #{name.capitalize()} < Backbone.Model
  initializer: ->
    # ...
    
this.#{name.capitalize()} = #{name.capitalize()}
",

    "test/fixtures/#{name}s.yml" : "
one:
  # ...

two:
  # ...
",

    "test/models/#{name}.#{project.language}" : "
module('#{name} model');

test('model exists'), ->
  ok(#{model.capitalize()})
  
test('truth'), ->
  ok(true)

  

"
  }
  
  
  
  






















