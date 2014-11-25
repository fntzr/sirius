describe "Model2View", ->
  Sirius.Application.adapter = new JQueryAdapter()

  describe "attribute 2 text", ->

    element = "div.model2view div.attribute2text"
    id_element = "#{element} .model-id"
    title_element = "#{element} .model-title"
    desc_element = "#{element} .model-description"

    view = new Sirius.View(element)
    model = new MyModel()

    model.bind(view)

    id = "1234567"
    title = "new title"
    descrption = "lorem ipsum dolore"

    beforeAll () ->
      model.id(id)
      model.title(title)
      model.description(descrption)


    it "should have inner text as model attributes", ->
      expect($(id_element).text()).toEqual(id)
      expect($(title_element).text()).toEqual(title)
      expect($(desc_element).text()).toEqual(descrption)


  describe "attribute to attribute", ->
    element = "div.model2view div.attribute2attribute"
    id_element = "#{element} .model-id"
    title_element = "#{element} .model-title"
    desc_element = "#{element} .model-description"

    view = new Sirius.View(element)
    model = new MyModel()

    model.bind(view)

    id = "1234567"
    title = "new title"
    descrption = "lorem ipsum dolore"

    beforeAll () ->
      model.id(id)
      model.title(title)
      model.description(descrption)


    it "should have attributes as model attributes", ->
      expect($(id_element).data('name')).toEqual(id)
      expect($(title_element).data('name')).toEqual(title)
      expect($(desc_element).data('name')).toEqual(descrption)

  describe "attribute to form", ->
    element = "div.model2view div.attribute2form"
    title_element = "#{element} input"
    desc_element = "#{element} textarea"

    view = new Sirius.View(element)
    model = new MyModel()

    model.bind(view)

    title = "new title"
    descrption = "lorem ipsum dolore"

    beforeAll () ->
      model.title(title)
      model.description(descrption)


    it "should have values as model attributes", ->
      expect($(title_element).val()).toEqual(title)
      expect($(desc_element).val()).toEqual(descrption)

  describe "attribute to form for logical attributes", ->
    element = "div.model2view div.forms"
    model = new MyModel()

    simpleForm = new Sirius.View("#{element} form.simple")
    selectForm = new Sirius.View("#{element} form.select")
    checkForm = new Sirius.View("#{element} form.check")
    radioForm = new Sirius.View("#{element} form.radio")

    model.bind(simpleForm)
    model.bind(selectForm)
    model.bind(checkForm)
    model.bind(radioForm)

    title = "title3"

    beforeAll () ->
      model.title(title)

    it "should have correct attributes", ->
      expect($("#{element} form.simple span.title-attr").data('name')).toEqual(title)
      expect($("#{element} form.simple span.title-text").text()).toEqual(title)
      expect($("#{element} form.simple input").val()).toEqual(title)

      expect($("#{element} form.select").find(":selected").text()).toEqual(title)

      expect($("#{element} form.check").find(":checked").val()).toEqual(title)

      expect($("#{element} form.radio").find(":checked").val()).toEqual(title)


