fs = require('fs')
sys = require('sys')
Path = require("path")
Glob = require("glob").globSync

root = __dirname + "/../"
router = require("#{root}/lib/router")
request = require("#{root}/lib/request")
_ = require("#{root}/lib/underscore")
yaml = require("#{root}/lib/yaml")
server = router.getServer()

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
    @root = cwd
    @yaml = yaml.eval(fs.readFileSync(@configPath()) + "")

  name : ->
    @cwd.replace(/.+\//,'')

  language : ->
    'coffee' # or 'js'
    
  configPath : ->
    Path.join(@cwd, "config.yml")
    
  getScriptTagFor: (path) ->
    if path.match(/coffee$/)
      "<script src='#{path}' type='text/coffeescript'></script>"
    else
      "<script src='#{path}' type='text/javascript'></script>"
      
  testScriptIncludes: ->
    tags = for path in Glob(Path.join(@cwd, "test", "**", "*.#{@language()}"))
      script = path.replace(@cwd, '')
      @getScriptTagFor script
      
    tags.join("\n")

  scriptIncludes : ->
    scripts = _([])

    for pathspec in @yaml.javascripts
      for path in Glob(Path.join(@cwd, pathspec))
        path = path.replace(@cwd, '')
        
        if not scripts.include? path
          scripts.push path

    tags = for script in scripts.value()
      @getScriptTagFor script
      
    tags.join("\n")
    
  styleIncludes : ->
    

#
# Start the server
#  
if data.arguments[0] == "server"
  project = new Project(process.cwd())
  
  server.get "/", (req, res, match) ->
    ejs = fs.readFileSync("#{project.root}/index.jst") + ""
    _.template(ejs, { project : project })

  server.get "/test/", (req, res) ->
    ejs = fs.readFileSync("#{root}/templates/html/runner.jst") + ""
    _.template(ejs, { project : project })

  server.get /(.*)/, router.staticDirHandler(project.root, '/')
  
  # (req, res, file) ->
  #   sys.puts "wtf?"
  #   # server.staticHandler("test/#{file}")
  #   try
  #     res.simpleText(200, fs.readFileSync(Path.join(project.root, file)) + "\n\n\n")
  #   catch e
  #     res.notFound()

  server.listen(3000)
  

#
# New project
#
if data.arguments[0] == "new"
  project = data.arguments[1] or raise("Must supply a name for new project.")

  sys.puts " * Creating folders"

  dirs = ["", "app", "app/views", "app/views/jst", "app/controllers", "app/models", "lib", "public", "public/stylesheets", "test", "test/controllers", "test/views", "test/models", "test/fixtures"]
  
  for dir in dirs
    fs.mkdirSync "#{project}/#{dir}", 0755

  sys.puts " * Downloading libraries"

  libs = {
    "lib/jquery.js" : "http://code.jquery.com/jquery-1.4.4.js", 
    "lib/underscore.js" : "http://documentcloud.github.com/underscore/underscore.js"
    "lib/backbone.js" : "http://documentcloud.github.com/backbone/backbone.js"
    "lib/coffeescript.js" : "http://jashkenas.github.com/coffee-script/extras/coffee-script.js"
    "test/qunit.js" : "http://github.com/jquery/qunit/raw/master/qunit/qunit.js"
    "test/qunit.css" : "http://github.com/jquery/qunit/raw/master/qunit/qunit.css"
    "config.yml" : Path.join(root, "templates/config.yml")
    "index.jst" : Path.join(root, "templates/html/index.jst")
  }
  
  downloadLibrary = (path, lib) ->
    request { uri : lib }, (error, response, body) ->
      if (!error && response.statusCode == 200)
        fs.writeFileSync("#{project}/#{path}", body)

  copyLibrary = (path, lib) ->
    fs.writeFileSync(Path.join(project, path), fs.readFileSync(lib) + "")
  
  for path, lib of libs
    if lib.match(/^http/)
      downloadLibrary(path, lib)
    else
      copyLibrary(path, lib)
    
  # sys.puts "Done.\n"

#
# Generate model
#

if data.arguments[0] == "generate" and data.arguments[1] == "model"
  project = new Project(process.cwd())

  if data.arguments[2]
    model = data.arguments[2].toLowerCase()
  else
    raise("Must supply a name for the model")

  copyFile = (from, to) ->
    ejs = fs.readFileSync(from) + ""
    fs.writeFileSync(Path.join(project.root, to), _.template(ejs, { project : project, model : model }))
    sys.puts "Created #{to}"

  copyFile "#{root}/templates/models/model.coffee", "app/models/#{model}.#{project.language()}"
  copyFile "#{root}/templates/models/test.coffee", "test/models/#{model}.#{project.language()}"
  copyFile "#{root}/templates/models/fixture.yml", "test/fixtures/#{model}.yml"
