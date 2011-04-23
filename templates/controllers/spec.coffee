describe '<%= controller %> controller', ->

  it 'should handle the truth', ->
    expect(true).toBeTruthy()

  it 'should exist', ->
    expect(<%= controller.capitalize() %>Controller).toBeTruthy()

  it 'should instantiate', ->
    x = new <%= controller.capitalize() %>Controller
    expect(x instanceof <%= controller.capitalize() %>Controller).toBeTruthy()
    expect(x instanceof Backbone.Controller).toBeTruthy()

  it 'should have index method', ->
    x = new <%= controller.capitalize() %>Controller
    x.index()

    # Umm..?
    expect(true).toBeTruthy()
