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
Project = require("#{root}/src/project").Project

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

task = (command, description, func) ->
  length = command.split(' ').length
  
  if data.arguments.slice(0,length).join(" ") == command
    func(data.arguments.slice(length))
    
#
# Start the server
#  
task 'server', 'start a webserver', (arguments) ->
  project = new Project(process.cwd())
  project.targets = arguments

  server.get "/", (req, res, match) ->
    ejs = fs.readFileSync("#{project.root}/index.jst") + ""
    _.template(ejs, { project : project })

  server.get "/test/", (req, res) ->
    ejs = fs.readFileSync("#{root}/templates/html/runner.jst") + ""
    _.template(ejs, { project : project })

  server.get /(.*)/, router.staticDirHandler(project.root, '/')

  server.listen(3000)

task 'build', 'concatenate and minify all javascript and stylesheets for production', (arguments) ->
  project = new Project(process.cwd())
  project.targets = arguments

  sys.puts "Building #{project.name()}..."

  if project.targets.length > 0
    sys.puts " * Targets: #{project.targets.join(', ')}"
  else
    sys.puts "You must specify a target (eg web)"

  try
    fs.mkdirSync "#{project.root}/build", 0755
  catch e
    # .. ok ..

  output = "#{project.root}/build/#{project.targets[0]}"
  
  try
    fs.mkdirSync output, 0755
  catch e
    # .. ok ..

  sys.puts " * #{output}/bundled-javascript.js"
  sys.puts "   - " + project.getScriptDependencies().join("\n   - ")
  
  project.bundleJavascript("#{output}/bundled-javascript.js")

  project.scriptIncludes = ->
    project.getScriptTagFor('/bundled-javascript.js')
  
  project.stylesheetIncludes = ->
    project.getStyleTagFor('/bundled-stylesheet.js')
  
  ejs = fs.readFileSync("#{project.root}/index.jst") + ""
  fs.writeFileSync("#{output}/index.html", _.template(ejs, { project : project }))


task 'watch', 'watch files and regenerate test.html and index.html as needed', (arguments) ->
  project = new Project(process.cwd())
  project.targets = arguments

  timer = null
  
  doRebuild = ->
    sys.puts "Rebuilt project..."
    
    ejs = fs.readFileSync("#{project.root}/index.jst") + ""
    fs.writeFileSync("#{project.root}/index.html", _.template(ejs, { project : project }))

    ejs = fs.readFileSync("#{root}/templates/html/runner.jst") + ""
    fs.writeFileSync("#{root}/test.html", _.template(ejs, { project : project }))

  rebuild = ->
    if timer 
      clearTimeout timer

    timer = setTimeout(doRebuild, 25)

  for script in project.getFilesToWatch()
    fs.watchFile Path.join(project.root, script), ->
      rebuild()
      
  rebuild()

task 'new', 'create a new project', (arguments) ->
  project = arguments[0] or raise("Must supply a name for new project.")

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
    "lib/less.js" : "https://github.com/cloudhead/less.js/raw/master/dist/less-1.0.40.js"
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
    
task 'generate model', 'create a new model', (arguments) ->
  project = new Project(process.cwd())

  if arguments[0]
    model = arguments[0].toLowerCase()
  else
    raise("Must supply a name for the model")

  copyFile = (from, to) ->
    ejs = fs.readFileSync(from) + ""
    fs.writeFileSync(Path.join(project.root, to), _.template(ejs, { project : project, model : model }))
    sys.puts "Created #{to}"

  copyFile "#{root}/templates/models/model.coffee", "app/models/#{model}.#{project.language()}"
  copyFile "#{root}/templates/models/test.coffee", "test/models/#{model}.#{project.language()}"
  copyFile "#{root}/templates/models/fixture.yml", "test/fixtures/#{model}.yml"


task 'generate controller', 'create a new controller', (arguments) ->
  project = new Project(process.cwd())

  if arguments[0]
    controller = arguments[0].toLowerCase()
  else
    raise("Must supply a name for the controller")

  copyFile = (from, to) ->
    ejs = fs.readFileSync(from) + ""
    fs.writeFileSync(Path.join(project.root, to), _.template(ejs, { project : project, controller : controller }))
    sys.puts "Created #{to}"

  fs.mkdirSync "#{project.root}/app/views/#{controller}", 0755
  copyFile "#{root}/templates/controllers/controller.coffee", "app/controllers/#{controller}_controller.#{project.language()}"
  copyFile "#{root}/templates/controllers/test.coffee", "test/controllers/#{controller}_controller.#{project.language()}"
