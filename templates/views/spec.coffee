describe '<%= view %> view', ->

  it 'should handle the truth', ->
    expect(true).toBeTruthy()

  it 'should exist', ->
    expect(<%= view.capitalize() %>View).toBeTruthy()

  it 'should instantiate', ->
    x = new <%= view.capitalize() %>View
    expect(x instanceof <%= view.capitalize() %>View).toBeTruthy()
    expect(x instanceof Backbone.View).toBeTruthy()

  it 'should have render method', ->
    x = new <%= view.capitalize() %>View
    x.render()

    # Umm..?
    expect(true).toBeTruthy()
