fs = require('fs')
sys = require('sys')
yaml = require("#{root}/lib/yaml")
Path = require("path")
Glob = require("glob").globSync
exec = require('child_process').exec
_ = require("#{root}/lib/underscore")

String.prototype.capitalize = ->
  this.charAt(0).toUpperCase() + this.substring(1).toLowerCase()

class Project
  constructor: (cwd) ->
    @cwd = cwd
    @root = cwd
    @yaml = yaml.eval(fs.readFileSync(@configPath()) + "")

    # Include these sections of the config.yml (eg nokia, android or web)
    @targets = []

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
      
  getStyleTagFor: (path) ->
    if path.match(/less$/)
  	  "<link href='#{path}' rel='stylesheet/less' type='text/css' />"
    else
  	  "<link href='#{path}' media='screen' rel='stylesheet' type='text/css' />"

  testScriptIncludes: ->
    tags = for path in Glob(Path.join(@cwd, "test", "**", "*.#{@language()}"))
      script = path.replace(@cwd, '')
      @getScriptTagFor script
      
    tags.join("\n")

  bundleStylesheet : (filename) ->
    index = 0
    
    inputs = for script in @getStylesheetDependencies()
      index++
      if script.match /less$/
        exec("lessc #{@root}#{script} > /tmp/#{index}.css")
        "\"/tmp/#{index}.css\""
      else
        "\"#{@root}#{script}\""

    inputs = inputs.join " "

    # sys.puts("sleep 5; cat #{inputs} > /tmp/stylesheet.css; java -jar #{root}/bin/yuicompressor-2.4.2.jar --type css --charset utf-8 /tmp/stylesheet.css -o #{filename}")
    exec("sleep 5; cat #{inputs} > /tmp/stylesheet.css; java -jar #{root}/bin/yuicompressor-2.4.2.jar --type css --charset utf-8 /tmp/stylesheet.css -o #{filename}")


  bundleJavascript : (filename) ->
    index = 0
    
    inputs = for script in @getScriptDependencies()
      index++
      if script.match /coffee$/
        exec("coffee -p -c #{@root}#{script} > /tmp/#{index}.js")
        "--js /tmp/#{index}.js"
      else
        "--js #{@root}#{script}"

    inputs = inputs.join " "

    # sys.puts "java -jar #{root}/bin/compiler.jar #{inputs} --js_output_file #{filename}"
    exec("sleep 5; java -jar #{root}/bin/compiler.jar #{inputs} --js_output_file #{filename}")
    
  getFilesToWatch : ->
    result = @getScriptDependencies()
    result.push 'index.jst'
    result
    
  getScriptDependencies : () ->
    # if !env
    #   env = 'development'
    #   
    # if env == 'development'
    #   scripts = _(['/lib/coffeescript.js', '/lib/less.js'])
    # else
    #   

    scripts = _([])

    for pathspec in @yaml.common
      for path in Glob(Path.join(@cwd, pathspec))
        path = path.replace(@cwd, '').replace(/^[.\/]+/,'/')
        scripts.push path

    for target in @targets
      for pathspec in @yaml[target]
        for path in Glob(Path.join(@cwd, pathspec))
          path = path.replace(@cwd, '')
          scripts.push path

    scripts.unique()
    
  getDependencies: (section) ->
    result = _([])

    for pathspec in @yaml[section]
      for path in Glob(Path.join(@cwd, pathspec))
        path = path.replace(@cwd, '').replace(/^[.\/]+/,'/')
        result.push path

    result.value()

  getStylesheetDependencies : ->
    result = _([])

    for pathspec in @yaml.stylesheets
      for path in Glob(Path.join(@cwd, pathspec))
        path = path.replace(@cwd, '')
        result.push path
        
    result.unique()
    
  stylesheetIncludes : ->
    tags = for css in @getStylesheetDependencies()
      @getStyleTagFor css
      
    tags.join("\n")
    
  specIncludes : ->
    tags = for script in @getScriptDependencies()
      @getScriptTagFor script
      
    for script in @getDependencies('specs')
      tags.push @getScriptTagFor script
    
    tags.join("\n")

  scriptIncludes : ->
    tags = for script in @getScriptDependencies()
      @getScriptTagFor script
      
    tags.join("\n")
    

exports.Project = Project
