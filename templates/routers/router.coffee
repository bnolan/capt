class <%= router.capitalize() %>Router extends Backbone.Router
  routes :
    "<%= router %>/:id/edit" : "edit"
    "<%= router %>/new" : "new"
    "<%= router %>/:id" : "show"
    "<%= router %>" : "index"

  index: ->
    # new <%= router.capitalize() %>IndexView

@<%= router.capitalize() %>Router = <%= router.capitalize() %>Router
