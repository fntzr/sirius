
# @private
#
# This class should extract from element node all elements which contain information
# about binding (data-bind-*)
#
# extracted info:
# data-bind-from
# data-bind-to
# data-bind-strategy
# data-bind-view
# element selector
class Sirius.BindHelper

  # @param [String] - selector
  # @param [Object] - contain information for extract (data-bind-*)
  #                   and contain information from user
  #                   and then merge extracted info and passed
  #                   {to: 'data-bind-to', from: 'data-bind-from'
  #                    strategy: 'data-bind-strategy'
  #                    transform: 'data-bind-transform'
  #                    }
  constructor: (@element, @setting, @is_bind_view_to_model = true) ->
    @logger = Sirius.Application.get_logger()
  #
  # @param [T < Adapter] - current application adapter
  # @param [Object] - `to` and `from` if present
  #
  extract: (adapter, user_setting = {}) ->
    # when it contain only one element (no children)
    # it's a single mode

    to = @setting['to']
    from = @setting['from']
    strategy = @setting['strategy']
    transform = @setting['transform']
    default_from = @setting['default_from']
    default_to = @setting['default_to']
    is_bind_view_to_model = @is_bind_view_to_model
    result = []
    @logger.info("BindHelper: to: #{to}, from: #{from}")
    @logger.info("BindHelper: strategy: #{strategy}")
    @logger.info("BindHelper: transform: #{transform}")
    @logger.info("BindHelper: default from: #{default_from}")
    @logger.info("BindHelper: default to: #{default_to}")

    element = @element
    keys = Object.keys(user_setting)
    tmp_a = keys.filter((k) -> !Sirius.Utils.is_object(user_setting[k]))
    elements = if tmp_a.length == 0
      # extract sub elements
      @logger.info("BindHelper: use user setting for work with elements")
      # return [element, key]
      tmp = []
      Object.keys(user_setting).map (k) ->
        tag = adapter.get_attr("#{element} #{k}", 'tagName')
        type = adapter.get_attr("#{element} #{k}", 'type')
        if tag == "OPTION" || type == "checkbox"
          z = adapter.all("#{element} #{k}")
          for x in z
            tmp.push([x, k])
        else
          tmp.push([adapter.get("#{element} #{k}"), k])
      tmp  # need [[element, selector], ... ]
    else
      # fixme optimize this need extract only when element contain data-bind-*
      # need extract main element, and children
      @logger.info("BindHelper: seems `user_setting`: #{tmp_a} contain non object, use extract with queryAll")
      # return [elements...]
      if is_bind_view_to_model
        adapter.all("#{element}[data-bind-to], #{element} *[data-bind-to]") # *
      else
        adapter.all("#{element}[data-bind-from], #{element} *[data-bind-from]") # *

    logger = @logger
    #
    # Extract all elements which contain data-bind-*
    # with data-bind-strategy
    # with data-bind-transform
    # and selector
    for element in elements
      do(element) ->
        if Sirius.Utils.is_array(element)
          key = user_setting[element[1]]
          if !key?
            msg = "BindHelper: Not found keys for binding for '#{key}' element"
            logger.error(msg)
            throw new Error(msg)

          tmp_to = key['to'] || default_to
          tmp_from = key['from'] || default_from
          tmp_strategy = key['strategy'] || 'swap'
          tmp_transform = key['transform']
          elem = element[0]

          if !elem?
            msg = "Element '#{element[1]}' not found. Check please."
            throw new Error(msg)
            logger.error(msg)

        else
          elem = element
          tmp_to   = adapter.get_attr(element, to) || default_to
          tmp_from = adapter.get_attr(element, from) || default_from
          tmp_strategy = adapter.get_attr(element, strategy) || 'swap'
          tmp_transform = adapter.get_attr(element, transform)
        # for view to model, need tmp_to but for model to view need tmp_from
        r = {
          to: tmp_to
          from: tmp_from
          strategy: tmp_strategy
          transform: tmp_transform
          element: elem
        }
        if is_bind_view_to_model
          if tmp_to
            result.push(r)
        else
          if tmp_from
            result.push(r)

    result




  # @throw [Error] when transform method not defined
  # @param [String] - function name
  # @param [Object]
  # @return [Function] - return transform function from setting
  @transform: (name, setting = {}) ->
    if Sirius.Utils.is_function(name)
      return name
    error = (name) -> "Transform method '#{name}' not found in setting"
    logger = Sirius.Application.get_logger()
    if Sirius.Utils.is_function(setting.transform)
      if name
        msg = error(name)
        logger.error("BindHelper: #{msg}")
        throw new Error(msg)
      else
        setting.transform
    else #when it object need extract necessary method
      if setting.transform[name]?
        setting.transform[name]
      else
        logger.warn("BindHelper: Transform method not found use default transform method: '(x) -> x'")
        (x) -> x
