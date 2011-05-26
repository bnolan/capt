class <%= controller.capitalize() %><%= view.capitalize() %>View extends Backbone.View
  initialize: ->
    
  render: ->
    $(@el).html("blah!")

@<%= controller.capitalize() %><%= view.capitalize() %>View = <%= controller.capitalize() %><%= view.capitalize() %>View
