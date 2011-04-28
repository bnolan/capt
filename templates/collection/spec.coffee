describe '<%= model %> collection', ->

  it 'should handle the truth', ->
    expect(true).toBeTruthy()

  it 'should exist', ->
    expect(<%= model.capitalize() %>Collection).toBeTruthy()

  it 'should instantiate', ->
    x = new <%= model.capitalize() %>Collection
    expect(x instanceof <%= model.capitalize() %>Collection).toBeTruthy()
    expect(x instanceof Backbone.Collection).toBeTruthy()
    expect(x.model == <%= model.capitalize() %>).toBeTruthy()

