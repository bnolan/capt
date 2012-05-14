describe '<%= router %> router', ->

  it 'should handle the truth', ->
    expect(true).toBeTruthy()

  it 'should exist', ->
    expect(<%= router.capitalize() %>Router).toBeTruthy()

  it 'should instantiate', ->
    x = new <%= router.capitalize() %>Controller
    expect(x instanceof <%= router.capitalize() %>Router).toBeTruthy()
    expect(x instanceof Backbone.Router).toBeTruthy()

  it 'should have index method', ->
    x = new <%= router.capitalize() %>Router
    x.index()

    # Umm..?
    expect(true).toBeTruthy()
