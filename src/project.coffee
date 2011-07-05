fs = require('fs')
sys = require('sys')
yaml = require("#{root}/lib/yaml")
Path = require("path")
Glob = require("glob").globSync
exec = require('child_process').exec
_ = require("#{root}/lib/underscore")
CoffeeScript  = require 'coffee-script'
eco = require "eco"
LessParser = require('less').Parser

sys.puts "Capt:"
sys.puts " * Using coffeescript version #{CoffeeScript.VERSION}"

String.prototype.capitalize = ->
  this.charAt(0).toUpperCase() + this.substring(1).toLowerCase()

class Project
  constructor: (cwd) ->
    @cwd = cwd
    @root = cwd
    try
      @yaml = yaml.eval(fs.readFileSync(@configPath()) + "\n\n")
    catch e
      sys.puts " * [ERROR] Unable to parse config.yml"
      sys.puts " * [ERROR] #{e.message}"
      process.exit(-1)

    # Include these sections of the config.yml (eg nokia, android or web)
    @targets = []

  name : ->
    @cwd.replace(/.+\//,'')

  language : ->
    'coffee' # or 'js'
    
  configPath : ->
    Path.join(@cwd, "config.yml")

  getScriptPathFor: (path) ->
    if Path.extname(path) == '.eco'
      # Eco templates
      Path.join(Path.dirname(path), ".js", Path.basename(path, '.eco') + '.js')
    else if Path.extname(path) == '.json'
      # Fixtures
      Path.join(Path.dirname(path), ".js", Path.basename(path, '.json') + '.js')
    else if Path.extname(path) == '.xml'
      # Fixtures
      Path.join(Path.dirname(path), ".js", Path.basename(path, '.xml') + '.js')
    else if Path.extname(path) == '.coffee'
      # Coffeescript
      Path.join(Path.dirname(path), ".js", Path.basename(path, '.coffee') + '.js')
    else
      # Javascript
      path
    
  getScriptTagFor: (path) ->
    path = @getScriptPathFor(path)
    "<script src='#{path}' type='text/javascript'></script>"
      
  getStyleTagFor: (path) ->
    if Path.extname(path) == '.less'
      # LESS CSS compiler
      csspath = Path.join(Path.dirname(path), "." + Path.basename(path, '.less') + '.css')
      "<link href='#{csspath}' media='screen' rel='stylesheet' type='text/css' />"
    else
      "<link href='#{path}' media='screen' rel='stylesheet' type='text/css' />"

  bundleStylesheet : (filename) ->
    console.log "Bundle Stylesheet not implemented..."
    # 
    # index = 0
    # 
    # inputs = for script in @getStylesheetDependencies()
    #   index++
    #   if script.match /less$/
    #     exec("lessc #{@root}#{script} > /tmp/#{index}.css")
    #     "\"/tmp/#{index}.css\""
    #   else
    #     "\"#{@root}#{script}\""
    # 
    # inputs = inputs.join " "
    # 
    # # sys.puts("sleep 5; cat #{inputs} > /tmp/stylesheet.css; java -jar #{root}/bin/yuicompressor-2.4.2.jar --type css --charset utf-8 /tmp/stylesheet.css -o #{filename}")
    # exec("sleep 5; cat #{inputs} > /tmp/stylesheet.css; java -jar #{root}/bin/yuicompressor-2.4.2.jar --type css --charset utf-8 /tmp/stylesheet.css -o #{filename}")


  # createManifest : ->
  #     [].concat(
  #       @getDependencies('specs')
  #       @getScriptDependencies()
  #       @getStylesheetDependencies()
  #     )
  #   
  bundleJavascript : (filename) ->
    index = 0
    
    inputs = for script in @getScriptDependencies()
      path = Path.join(@root, @getScriptPathFor(script))

    inputs = inputs.join " "

    # sys.puts inputs
    # sys.puts "java -jar #{root}/bin/compiler.jar #{inputs} --js_output_file #{filename}"

    # exec("java -jar #{root}/bin/compiler.jar --compilation_level WHITESPACE_ONLY #{inputs} --js_output_file #{filename}")
    # sys.puts("cat #{inputs} > #{filename}")
    exec("cat #{inputs} > #{filename}")
    
  getScriptDependencies : () ->
    [].concat(
      @getDependencies('javascripts')
      @getDependencies('templates')
    )
    #
    # 
    # scripts = _([])
    # 
    # @getDependencies('templates')
    # 
    # for pathspec in @yaml.javascripts
    #   for path in Glob(Path.join(@cwd, pathspec))
    #     path = path.replace(@cwd, '').replace(/^[.\/]+/,'/')
    #     scripts.push path
    # # 
    # # for target in @targets
    # #   for pathspec in @yaml[target]
    # #     for path in Glob(Path.join(@cwd, pathspec))
    # #       path = path.replace(@cwd, '')
    # #       scripts.push path
    # 
    # scripts.unique()
    
  getDependencies: (section) ->
    if !@yaml[section]
      if section == 'static'
        return ['/index.jst', '/spec/index.jst']
        
      sys.puts "[WARNING] Unable to find section '#{section}' in config.yml"
      return []
      
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
      
    tags.join("\n  ")
    
  specIncludes : ->
    tags = for script in @getScriptDependencies()
      @getScriptTagFor(Path.join("..", script))
      
    for script in @getDependencies('specs')
      tags.push @getScriptTagFor(Path.join("..", script))

    for script in @getDependencies('fixtures')
      tags.push @getScriptTagFor(Path.join("..", script))
    
    tags.join("\n  ")

  scriptIncludes : ->
    tags = for script in @getScriptDependencies()
      @getScriptTagFor script
      
    tags.join("\n  ")

  compileFile : (file) ->
    extension = Path.extname(file)
    
    if extension == ".coffee"
      @_compileCoffee(file)
    else if extension == ".less"
      @_compileLess(file)
    else if extension == ".xml"
      @_compileXml(file)
    else if extension == ".json"
      @_compileJson(file)
    else if extension == ".eco"
      @_compileEco(file)
    else if extension == ".jst"
      @_compileJst(file)
    else
      # do nothing...

  getWatchables : ->
    [].concat(
      @getDependencies('static')
      @getDependencies('specs')
      @getDependencies('fixtures')
      @getScriptDependencies()
      @getStylesheetDependencies()
    )
    
  _compileLess : (file) ->
    parser = new LessParser {
       # Specify search paths for @import directives
        paths: ['.', 'public/stylesheets'],
        
        # Specify a filename, for better error messages
        filename: file 
    }
    
    fs.readFile Path.join(@root, file), (err, code) =>
      throw err if err

      path = Path.dirname(file)
      outpath = Path.join(path, "." + Path.basename(file, ".less") + ".css")
    
      try
        fs.mkdirSync Path.join(@root, path), 0755
      catch e
        # .. ok ..

      parser.parse code.toString(), (e, css) =>
        if e
          sys.puts " * Error compiling #{file}"
          sys.puts err.message
        else
          sys.puts " * Compiled " + outpath
          fs.writeFileSync Path.join(@root, outpath), css.toCSS()
    
  # Compile xml fixtures
  _compileXml : (file) ->
    fs.readFile Path.join(@root, file), "utf-8", (err, code) =>
      throw err if err

      path = Path.join(Path.dirname(file), ".js")
      outpath = Path.join(path, Path.basename(file, ".xml") + ".js")

      try
        fs.mkdirSync Path.join(@root, path), 0755
      catch e
        # .. ok ..

      templateName = [
        Path.dirname(file).split("/").pop().toLowerCase()
        Path.basename(file, ".xml").capitalize()
      ].join("")
      
      output = "if(!this.$fixtures){\n  $fixtures={};\n};\n\n" + 
        "this.$fixtures.#{templateName}=$(\"" + 
        code.replace(/"/g,"\\\"").replace(/\n/g,"\\n") + 
        "\");"
      
      sys.puts " * Compiled " + outpath
      fs.writeFileSync Path.join(@root, outpath), output
    
  # Compile json fixtures
  _compileJson : (file) ->
    fs.readFile Path.join(@root, file), "utf-8", (err, code) =>
      throw err if err

      path = Path.join(Path.dirname(file), ".js")
      outpath = Path.join(path, Path.basename(file, ".json") + ".js")

      try
        fs.mkdirSync Path.join(@root, path), 0755
      catch e
        # .. ok ..

      templateName = [
        Path.dirname(file).split("/").pop().toLowerCase()
        Path.basename(file, ".json").capitalize()
      ].join("")

      output = "if(!this.$fixtures){\n  $fixtures={};\n};\n\n" + 
        "this.$fixtures.#{templateName}=" + code.toString() + ";"

      sys.puts " * Compiled " + outpath
      fs.writeFileSync Path.join(@root, outpath), output

  _compileCoffee : (file) ->
    fs.readFile Path.join(@root, file), (err, code) =>
      throw err if err

      path = Path.join(Path.dirname(file), ".js")
      outpath = Path.join(path, Path.basename(file, ".coffee") + ".js")
    
      try
        fs.mkdirSync Path.join(@root, path), 0755
      catch e
        # .. ok ..
    
      try
        output = CoffeeScript.compile(new String(code))
      catch err
        sys.puts " * Error compiling #{file}"
        sys.puts err.message
        return
        
      sys.puts " * Compiled " + outpath
      fs.writeFileSync Path.join(@root, outpath), output

  _compileEco : (file) ->
    fs.readFile Path.join(@root, file), "utf-8", (err, code) =>
      throw err if err

      path = Path.join(Path.dirname(file), ".js")
      outpath = Path.join(path, Path.basename(file, ".eco") + ".js")

      try
        fs.mkdirSync Path.join(@root, path), 0755
      catch e
        # .. ok ..

      try
        output = eco.compile(new String(code))
      catch err
        sys.puts " * Error compiling #{file}"
        sys.puts err.message
        return

      templateName = [
        Path.dirname(file).split("/").pop().toLowerCase()
        Path.basename(file, ".eco").capitalize()
      ].join("")
      
      output = output.replace(/^module.exports/, "this.$templates.#{templateName}")
      output = "if(!this.$templates){\n  $templates={};\n};\n\n" + output
      
      sys.puts " * Compiled " + outpath
      fs.writeFileSync Path.join(@root, outpath), output

  _compileJst : (file) ->
    fs.readFile Path.join(@root, file), (err, code) =>
      throw err if err

      outpath = Path.join(Path.dirname(file), Path.basename(file, '.jst') + ".html")
      
      try
        output = _.template(new String(code), { project : this })
      catch err
        sys.puts " * Error compiling #{file}"
        sys.puts err.message
        return

      sys.puts " * Compiled " + outpath
      fs.writeFileSync Path.join(@root, outpath), output
    
  watchAndBuild: ->
    watch = (source) =>
      fs.watchFile Path.join(@root, source), {persistent: true, interval: 500}, (curr, prev) =>
        return if curr.size is prev.size and curr.mtime.getTime() is prev.mtime.getTime()
        @compileFile(source)

    for source in @getWatchables()
      watch(source)
      @compileFile(source)

exports.Project = Project
