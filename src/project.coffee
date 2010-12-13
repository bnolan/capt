fs = require('fs')
sys = require('sys')
yaml = require("#{root}/lib/yaml")
Path = require("path")
Glob = require("glob").globSync
_ = require("#{root}/lib/underscore")

String.prototype.capitalize = ->
  this.charAt(0).toUpperCase() + this.substring(1).toLowerCase()

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
        scripts.push path

    tags = for script in scripts.value()
      @getScriptTagFor script
      
    tags.join("\n")
    
  styleIncludes : ->
    

exports.Project = Project