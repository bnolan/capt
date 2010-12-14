class <%= controller.capitalize() %>Controller extends Backbone.Controller
  routes :
    "<%= controller %>-:cid-edit" : "edit"
    "<%= controller %>-new" : "new"
    "<%= controller %>-:cid" : "show"
    "<%= controller %>" : "index"
    
  initialize: ->
    @_views = []
    
  index: ->
    @_views['<%= controller %>-index'] ||= new <%= controller.capitalize() %>IndexView
    
new <%= controller.capitalize() %>Controller
