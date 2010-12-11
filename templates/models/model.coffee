class <%= model.capitalize() %> < Backbone.Model
  initializer: ->
    # ...
    
this.<%= model.capitalize() %> = <%= model.capitalize() %>
