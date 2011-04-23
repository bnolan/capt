class <%= view.capitalize() %>View extends Backbone.View
  events:

  initialize: ->
    _.bindAll(@, 'render')

  render: ->

@<%= view.capitalize() %>View = <%= view.capitalize() %>View

new <%= view.capitalize() %>View
