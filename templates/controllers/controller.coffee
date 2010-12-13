class <%= controller.capitalize() %> extends Backbone.Controller
  routes :
    "<%= controller %>-:cid-edit" : "edit"
    "<%= controller %>-new" : "new"
    "<%= controller %>-:cid" : "show"
    "<%= controller %>" : "index"
    
  initialize: ->
    @_views = []
    
  index: ->
    @_views['<%= controller %>-index'] ||= new <%= controller.capitalize() %>IndexView
    
Backbone._controllers ||= []
Backbone._controllers.push(<%= controller.capitalize() %>Controller)
