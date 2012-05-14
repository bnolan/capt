class <%= router.capitalize() %><%= view.capitalize() %>View extends Backbone.View
  initialize: ->
    
  render: ->
    $(@el).html("blah!")

@<%= router.capitalize() %><%= view.capitalize() %>View = <%= router.capitalize() %><%= view.capitalize() %>View
