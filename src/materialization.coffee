
###

  probably like:

  Materializer.build(T <: BaseModel|View, R <: BaseModel|View|Function)
  .field((x) -> s.attr())               # does it possible in coffee?
  # or
  field('attr_name').to("input").attribute("data-attr").with(() ->)

  field('attr_name).to("input")
  .dump() => log output as string, dump is a terminal operation
  # or build
  # does it possible?
  field('attr_name').to((v) -> v.zoom('input')).attribute('data-attr').with(() -> )

  # TODO spec syntax, add to .prototype.
  field((model) -> model.from{or something like that}.attr())
  field( view -> view.zoom("el"))

  # view to view
  Materializer.build(v1, v2)
  .field("element").from("attribute").to("element).with((v2, v1_attribute) -> )
  .field(v -> v.zoom("element")).from("attribute").to(v2 -> v.zoom("el"))
  .with(() ->)
  # or
  .field("element").from("attr").with((v2, attr) -> ) # user decides what should do with v2 (zoom) and attr

 # view to model
  Materilizer.build(v, m)
  .field("element").from("attr").to('m_attr')
  .field(v -> v.zoom("el")).from("attr").to(m -> m.attr_name)
   with ? (m, attr_changes) -> ??? is it need?

 # view to function
  Materializer.build(v) # second param is empty
  .field('element').attribute('data-class').to((changes) ->)

 # model to function
 Materializer.build(m) # second param is empty
  .field('attr').to(changes) -> )

 # first iteration:
  - third integration with current


###


# ok, it's for BaseModelToView
class FieldMaker
  constructor: (@_from, @_to, @_attribute, @_transform, @_handle) ->

  has_to: () ->
    @_to?

  has_attribute: () ->
    @_attribute?

  has_transform: () ->
    @_transform?

  has_handle: () ->
    @_handle?

  field: () ->
    @_from

  to: (x) ->
    if x?
      @_to = x
    else
      @_to

  handle: (x) ->
    if x?
      @_handle = x
    else
      @_handle

  attribute: (x) ->
    if x?
      @_attribute = x
    else
      @_attribute

  transform: (x) ->
    if x?
      @_transform = x
    else
      @_transform

  # fill with default parameters
  normalize: () ->
    if !@has_transform()
      @_transform = (x) -> x

    if !@has_attribute()
      @_attribute = "text" # make constant


  to_string: () ->
    "#{@_from} ~> #{@_transform} ~> #{@_to}##{@_attribute}"

  @build: (from) ->
    new FieldMaker(from)


class AbstractMaterializer
  constructor: (@_from, @_to) ->
    @fields = []
    @current = null

  field: (from_name) ->
    if @current?
      @current.normalize()

    @current = FieldMaker.build(from_name)
    @fields.push(@current)

  _zoom_with: (view, maybeView) ->
    if Sirius.Utils.is_string(maybeView)
      view.zoom(maybeView)
    else
      maybeView

  dump: () ->
    xs = @fields.map (x) -> x.to_string()
    xs.join("\n")

  to_string: () ->
    @dump()

  get_from: () ->
    @_from

  get_to: () ->
    @_to()

  has_to: () ->
    @_to?

  materialize: () ->
    @fields

  run: () ->
    throw new Error("Not Implemented")


# interface-like
class MaterializerWithImpl extends AbstractMaterializer

  transform: (f) ->
    unless Sirius.Utils.is_function(f)
      throw new Error("'transform' attribute must be function, #{typeof f} given")

    unless @current?
      throw new Error("Incorrect call. Call 'transform' after 'to' or 'attribute'")

    unless @current.has_to()
      throw new Error("Incorrect call. Call 'to' before 'transform'")

    if @current.has_transform()
      throw new Error("Incorrect call. The field already has 'transform' function")

    @current.transform(f)
    @



class ModelToViewMaterializer extends MaterializerWithImpl
  field: (from_name) ->
    result = from_name
    if Sirius.Utils.is_function(from_name)
      result = from_name(@_from.get_binding())

    Materializer._check_model_compliance(@_from, result)

    super.field(result)

    @

  to: (arg) ->
    unless @current?
      throw new Error("Incorrect call. Call 'to' after 'field'")

    unless Sirius.Utils.is_function(arg) || Sirius.Utils.is_string(arg) || arg instanceof Sirius.View
      throw new Error("'to' must be string or function, or instance of Sirius.View")

    result = arg
    if Sirius.Utils.is_string(arg)
      result = @_zoom_with(@_to, arg)

    if Sirius.Utils.is_function(arg)
      result = @_zoom_with(@_to, arg(@_to))

    if @current.has_to()
      throw new Error("Incorrect call. '#{@current.field()}' already has 'to'")

    @current.to(result)
    @

  attribute: (attr) ->
    unless @current?
      throw new Error("Incorrect call. Define 'field' firstly, and then call 'attribute' after 'to'")

    unless @current.has_to()
      throw new Error("Incorrect call. Call 'to' before 'attribute'")

    if @current.has_attribute()
      throw new Error("Incorrect call. '#{@current.field()}' already has 'attribute'")

    @current.attribute(attr)
    @

  handle: (f) ->
    unless @current?
      throw new Error("Incorrect call. 'field' is not defined")

    unless @current.has_to()
      throw new Error("Incorrect call. define 'to'")

    unless Sirius.Utils.is_function(f)
      throw new Error("'handle' must be a function")

    if @current.has_handle()
      throw new Error("'handle' already defined")

    @current.handle(f)
    @


  run: () ->
    obj = {}
    for f in @fields
      obj[f.field()] = f
    clb = (attribute, changes) ->
      if obj[attribute]?
        f.trnaform(changes, f.to())


class ViewToModelMaterializer extends MaterializerWithImpl
  field: (element) ->
    el = null
    if Sirius.Utils.is_string(element)
      el = @_from.zoom(element)
    else if Sirius.Utils.is_function(element)
      el = @_zoom_with(@_from, element(@_from))
    else if element instanceof Sirius.View
      el = element
    else
      throw new Error("Element must be string or function, or instance of Sirius.View")

    super.field(el)
    @

  from: (attribute) ->
    unless @current?
      throw new Error("Incorrect call. Define 'field' firstly, and then call 'from'")

    if @current.has_to()
      throw new Error("Incorrect call. Call 'from' before 'to'")

    if @current.has_attribute()
      throw new Error("Incorrect call. '#{@current.field().get_element()}' already has 'from'")

    @current.attribute(attribute)
    @

  to: (attribute) ->
    unless @current?
      throw new Error("Incorrect call. Define 'field' firstly, and then call 'from'")

    if @current.has_to()
      throw new Error("Incorrect call. '#{@current.field().get_element()}' already has 'to'")

    result = attribute
    if @_to? && Sirius.Utils.is_function(attribute)
      result = attribute(@_to.get_binding())

    if @_to? && @_to instanceof Sirius.BaseModel
      Materializer._check_model_compliance(@_to, result)

    @current.to(result)
    @

class ViewToViewMaterializer extends ViewToModelMaterializer
  to: (element) ->
    el = null
    if Sirius.Utils.is_string(element)
      el = @_to.zoom(element)
    else if element instanceof Sirius.View
      el = element
    else if Sirius.Utils.is_function(element)
      el = @_zoom_with(@_to, element(@_to))
    else
      throw new Error("Element must be string or function, or instance of Sirius.View")

    super.to(el)
    @

  handle: (f) ->
    unless @current?
      throw new Error("Incorrect call. 'field' is not defined")

    unless @current.has_to()
      throw new Error("Incorrect call. define 'to'")

    unless Sirius.Utils.is_function(f)
      throw new Error("'handle' must be a function")

    if @current.has_handle()
      throw new Error("'handle' already defined")

    @current.handle(f)
    @

class ViewToFunctionMaterializer extends ViewToModelMaterializer
  to: (f) ->
    unless Sirius.Utils.is_function(f)
      throw new Error("Function is required")

    super.to(f)
    @

class ModelToFunctionMaterializer extends AbstractMaterializer
  field: (attr) ->
    result = attr
    if Sirius.Utils.is_function(attr)
      result = attr(@_from.get_binding())

    Materializer._check_model_compliance(@_from, result)

    super.field(result)

    @

  to: (f) ->
    unless @current?
      throw new Error("Incorrect call. Define 'field' firstly")

    if @current.has_to()
      throw new Error("Incorrect call. The field already has 'to'")

    unless Sirius.Utils.is_function(f)
      throw new Error("Function is required")

    @current.to(f)
    @


class Materializer

  # from must be View or BaseModel
  # to is View, BaseModel, or Function
  constructor: (from, to) ->
    if from instanceof Sirius.BaseModel && to instanceof Sirius.View
      return new ModelToViewMaterializer(from, to)
    if from instanceof Sirius.View && to instanceof Sirius.BaseModel
      return new ViewToModelMaterializer(from, to)
    if from instanceof Sirius.View && to instanceof Sirius.View
      return new ViewToViewMaterializer(from, to)
    if from instanceof Sirius.View && !to?
      return new ViewToFunctionMaterializer(from)
    if from instanceof Sirius.BaseModel && !to?
      return new ModelToFunctionMaterializer(from)
    else
      throw new Error("Illegal arguments: 'from'/'to' must be instance of Sirius.View/or Sirius.BaseModel")

  @_check_model_compliance: (model, maybe_model_attribute) ->
    name = model._klass_name()
    attrs = model.get_attributes()

    if attrs.indexOf(maybe_model_attribute) != -1
      return true
    else
      if maybe_model_attribute.indexOf(".") == -1
        throw new Error("Attribute '#{maybe_model_attribute}' not found in model attributes: '#{name}', available: '[#{attrs}]'")

      # check for validators
      splitted = maybe_model_attribute.split(".")
      if splitted.length != 3
        throw new Error("Try to bind '#{maybe_model_attribute}' from errors properties, but validator is not found, correct definition should be as 'errors.id.numericality'")

      [_, attr, validator_key] = splitted

      unless model._is_valid_validator("#{attr}.#{validator_key}")
        throw new Error("Unexpected '#{maybe_model_attribute}' errors attribute for '#{name}' (check validators)")
      else
        return true


  @build: (from, to) ->
    new Materializer(from, to)













