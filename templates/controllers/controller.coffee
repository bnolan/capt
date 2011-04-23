class <%= controller.capitalize() %>Controller extends Backbone.Controller
  routes :
    "<%= controller %>/:id/edit" : "edit"
    "<%= controller %>/new" : "new"
    "<%= controller %>/:id" : "show"
    "<%= controller %>" : "index"

  index: ->
    # new <%= controller.capitalize() %>IndexView

@<%= controller.capitalize() %>Controller = <%= controller.capitalize() %>Controller

new <%= controller.capitalize() %>Controller
