describe '<%= model %> model', ->

  it 'should handle the truth', ->
    expect(true).toBeTruthy()

  it 'should exist', ->
    expect(<%= model.capitalize() %>).toBeTruthy()

  it 'should instantiate', ->
    x = new <%= model.capitalize() %>
    expect(x instanceof <%= model.capitalize() %>).toBeTruthy()
    expect(x instanceof Backbone.Model).toBeTruthy()

