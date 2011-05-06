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
  minargs : 0
  maxargs : 10
}

$usage = '''
Usage:
  
  capt new projectname 
    - create a new project
    
  capt server
    - serve the current project on port 3000
      
  capt watch
    - watch the current project and recompile as needed

  Code generators:
    * capt generate model post
    * capt generate controller posts
    * capt generate view posts show
    
    
'''

# Parse command line
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
    task.done = true
    
#
# Start the server
#  
task 'server', 'start a webserver', (arguments) ->
  project = new Project(process.cwd())

  server.get "/", (req, res, match) ->
    ejs = fs.readFileSync("#{project.root}/index.jst") + ""
    _.template(ejs, { project : project })

  server.get "/spec/", (req, res) ->
    ejs = fs.readFileSync("#{project.root}/spec/index.jst") + ""
    _.template(ejs, { project : project })

  server.get /(.*)/, router.staticDirHandler(project.root, '/')

  project.watchAndBuild()
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

  sys.puts " * #{output}/bundled-stylesheet.css"
  sys.puts "   - " + project.getStylesheetDependencies().join("\n   - ")

  project.bundleStylesheet("#{output}/bundled-stylesheet.css")

  sys.puts " * #{output}/index.html"

  project.scriptIncludes = ->
    project.getScriptTagFor('/bundled-javascript.js')
  
  project.stylesheetIncludes = ->
    project.getStyleTagFor('/bundled-stylesheet.css')
  
  ejs = fs.readFileSync("#{project.root}/index.jst") + ""
  fs.writeFileSync("#{output}/index.html", _.template(ejs, { project : project }))


task 'watch', 'watch files and compile as needed', (arguments) ->
  project = new Project(process.cwd())
  project.watchAndBuild()

task 'new', 'create a new project', (arguments) ->
  project = arguments[0] or raise("Must supply a name for new project.")

  sys.puts " * Creating folders"

  dirs = ["", "spec", "spec/jasmine", "spec/models", "spec/controllers", "spec/views", "app", "app/views", "app/views/jst", "app/controllers", "app/models", "lib", "public", "public/stylesheets", "spec/fixtures"]

  for dir in dirs
    fs.mkdirSync "#{project}/#{dir}", 0755

  sys.puts " * Creating directory structure"

  libs = {
    "lib/jquery.js" : "lib/jquery.js", 
    "lib/underscore.js" : "lib/underscore.js"
    "lib/backbone.js" : "lib/backbone.js"
    "lib/less.js" : "lib/less.js"
    "app/controllers/application.coffee" : "controllers/application.coffee"
    "spec/jasmine/jasmine-html.js" : "lib/jasmine-html.js"
    "spec/jasmine/jasmine.css" : "lib/jasmine.css"
    "spec/jasmine/jasmine.js" : "lib/jasmine.js"
    "config.yml" : "config.yml"
    "index.jst" : "html/index.jst"
    "spec/index.jst" : "html/runner.jst"
  }
  
  downloadLibrary = (path, lib) ->
    request { uri : lib }, (error, response, body) ->
      if (!error && response.statusCode == 200)
        sys.puts "   * " + Path.basename(path)
        fs.writeFileSync("#{project}/#{path}", body)
      else
        sys.puts "   * [ERROR] Could not download " + Path.basename(path)

  copyLibrary = (path, lib) ->
    fs.writeFileSync(Path.join(project, path), fs.readFileSync(lib) + "")
  
  for path, lib of libs
    if lib.match(/^http/)
      downloadLibrary(path, lib)
    else
      copyLibrary(path, Path.join(root, "templates/", lib))
    
task 'generate model', 'create a new model', (arguments) ->
  project = new Project(process.cwd())

  if arguments[0]
    model = arguments[0].toLowerCase()
  else
    raise("Must supply a name for the model")

  copyFile = (from, to) ->
    ejs = fs.readFileSync(from) + ""
    fs.writeFileSync(Path.join(project.root, to), _.template(ejs, { project : project, model : model }))
    sys.puts " * Created #{to}"

  copyFile "#{root}/templates/models/model.coffee", "app/models/#{model}.#{project.language()}"
  copyFile "#{root}/templates/models/spec.coffee", "spec/models/#{model}.#{project.language()}"


task 'generate collection', 'create a new collection', (arguments) ->
  project = new Project(process.cwd())

  if arguments[0]
    model = arguments[0].toLowerCase()
  else
    raise("Must supply a name for the model")

  copyFile = (from, to) ->
    ejs = fs.readFileSync(from) + ""
    fs.writeFileSync(Path.join(project.root, to), _.template(ejs, { project : project, model : model }))
    sys.puts " * Created #{to}"

  copyFile "#{root}/templates/collection/collection.coffee", "app/models/#{model}_collection.#{project.language()}"
  copyFile "#{root}/templates/collection/spec.coffee", "spec/models/#{model}_collection.#{project.language()}"


task 'generate controller', 'create a new controller', (arguments) ->
  project = new Project(process.cwd())

  if arguments[0]
    controller = arguments[0].toLowerCase()
  else
    raise("Must supply a name for the controller")

  copyFile = (from, to) ->
    ejs = fs.readFileSync(from) + ""
    fs.writeFileSync(Path.join(project.root, to), _.template(ejs, { project : project, controller : controller }))
    sys.puts " * Created #{to}"

  try
    fs.mkdirSync "#{project.root}/app/views/#{controller}", 0755
  catch e
    # ...
    
  copyFile "#{root}/templates/controllers/controller.coffee", "app/controllers/#{controller}_controller.#{project.language()}"
  copyFile "#{root}/templates/controllers/spec.coffee", "spec/controllers/#{controller}_controller.#{project.language()}"

task 'generate view', 'create a new view', (arguments) ->
  project = new Project(process.cwd())

  if arguments[0] and arguments[1]
    controller = arguments[0].toLowerCase()
    view = arguments[1].toLowerCase()
  else
    raise("Must supply a name for the controller and then view")

  copyFile = (from, to) ->
    ejs = fs.readFileSync(from) + ""
    fs.writeFileSync(Path.join(project.root, to), _.template(ejs, { project : project, controller: controller, view : view }))
    sys.puts " * Created #{to}"

  try
    fs.mkdirSync "#{project.root}/app/views/#{controller}", 0755
  catch e
    # ...
    
  try
    fs.mkdirSync "#{project.root}/spec/views/#{controller}", 0755
  catch e
    # ...

  copyFile "#{root}/templates/views/view.coffee", "app/views/#{controller}/#{view}.#{project.language()}"
  copyFile "#{root}/templates/views/spec.coffee", "spec/views/#{controller}/#{view}.#{project.language()}"

# task 'spec', 'run the specs', (arguments) ->
#   project = new Project(process.cwd())
# 
#   sys.puts " * Running specs..."
#
#   jasmine = require('jasmine-node')
#   
#   runLogger = (runner, log) ->
#     if runner.results().failedCount == 0
#       process.exit 0
#     else
#       process.exit 1
#   
#   jasmine.executeSpecsInFolder "spec/models", runLogger, true, true

# No task was specified...

if !task.done
  sys.puts $usage
  process.exit()
