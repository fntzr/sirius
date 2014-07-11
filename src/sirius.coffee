###!
#  Sirius.js v0.1.1
#  (c) 2014 fntzr
#  license: MIT
###

#
# @author fntzr <fantazuor@gmal.com>
# @version 0.1.1
# @mixin
# A main module, which included methods and classes for work with application.
Sirius =
  VERSION: "0.1.1"

#
# Redirect to given url.
# @method .Sirius.redurect(url)
# @example
#   var Controller = {
#     action : function(params) {
#        if (params.length == 0)
#          Sirius.redirect("#"); //redirect to root url
#        else
#          //code
#     }
#
Sirius.redirect = (url) ->
  location.replace(url)

#
# Utils class with helpers for application
#
class Sirius.Utils
  #
  # @param [Any] a - check, that `a` is a Function
  # @return [Boolean] - true, when is Function, otherwise return false
  #
  @is_function: (a) ->
    Object.prototype.toString.call(a) is '[object Function]'
  #
  # @param [Any] a - check, that `a` is a String
  # @return [Boolean] - true, when is String, otherwise return false
  #
  @is_string: (a) ->
    Object.prototype.toString.call(a) is '[object String]'
  #
  # @param [Any] a - check, that `a` is a Array
  # @return [Boolean] - true, when is Array, otherwise return false
  #
  @is_array: (a) ->
    Object.prototype.toString.call(a) is '[object Array]'
  #
  # Upper case first letter in string
  #
  # @example
  #   Sirius.Utils.camelize("abc") // => Abc
  @camelize: (str) ->
    str.charAt(0).toUpperCase() + str.slice(1)

  #
  # Underline before upper case
  # @example
  #   Sirius.Utils.underscore("ModelName") // => model_name
  @underscore: (str) ->
    str.replace(/([A-Z])/g, '_$1').replace(/^_/,"").toLowerCase()

# @private
# Class for map urls.
#
# Also it's class contain extracted parts from url.
# ### Url syntax:
# ```coffee
# #/:param1/:param2   => extract param1, param2 ...
# #/[0-9]+            => extract param, which satisfy given regexp
# #/start/*           => extract all after /start/
# ```
class Sirius.RoutePart
  constructor: (route) ->
    @end   = yes  # when route have a end (ends with `*`)
    @start = null #not used ...
    @parts = []
    @args  = []
    # #/abc/dsa/ => ["#", "abc", "dsa"]
    parts = route.replace(/\/$/, "").split("/")

    # mark, this route not have a length and end
    #  #/title/id/*
    # matched with #/title/id/2014 and #/title/id/2014/2020 ...
    @end   = no if parts[parts.length - 1] == "*"

    @parts = parts[0..-1]

  #
  # Check if given url equal `parts` url
  #
  # When return true, then `args` contain extracted arguments:
  # @example
  #   var rp = new Sirius.RoutePart("#/post/:title")
  #   rp.match("#/abc") // => false
  #   rp.args          // => []
  #   rp.match("#/post/my-post-title") // => true
  #   rp.args                          // => ["my-post-title"]
  #
  #
  # @param url [String] - given url
  # @return [Boolean] true if matched, otherwise - return false
  match: (url) ->
    @args = []
    parts = url.replace(/\/$/, "").split("/")

    #when not end, and parts have a different length, this not the same routes
    return false if ((parts.length != @parts.length) && @end)
    #when it have a different length, but @parts len > given len
    return false if (@parts.length > 1) && parts.length < @parts.length

    is_named_part = (part) ->
      part.indexOf(":") == 0

    is_regexp_part = (part) ->
      part.indexOf("[") == 0

    is_end_part = (part) ->
      part.indexOf("*") == 0

    i = -1
    # protect
    args = []
    while i < 10
      i++
      [cp, gp] = [@parts[i], parts[i]]
      break if !cp || !gp
      if is_named_part(cp)
        args.push(parts[i])
        continue
      if is_regexp_part(cp)
        r = new RegExp("^#{cp}$");
        return false if !r.test(gp)
        args.push(r.exec(gp)[0])
        continue
      if is_end_part(cp)
        args = args.concat(parts[i..-1])
        break
      if cp != gp
        return false

    @args = args
    true


# @private
# Helper class, which check object for route, and have a method, which used as event listener.
# @example
#   "#/my-route" : { controller: Controller, action: "action", before: "before", after: "after", guard: "guard", "data" : ["data"] }
#
class Sirius.ControlFlow

  # @param params [Object] - object from route
  #
  # `params` is a object with have a next keys `controller`, `action`, `before`, `after`, `data`, `guard`.
  # @note `controller` required
  # @note `action` required
  # @note `before`must be a string, where string is a method from `controller` or function
  # @note `after` must be a string, where string is a method from `controller` or function
  # @note `guard` must be a string, where string is a method from `controller` or function
  # @note you might create in controller method with name: `before_x`, where `x` you action, then you may not specify `before` into params, it automatically find and assigned as `before` method, the same for `after` and `guard`
  # @note `data` must be a string, or array of string
  constructor: (params) ->
    controller = params['controller'] || throw new Error("Params must contain a Controller")


    act = params['action']

    @action = if Sirius.Utils.is_string(act)
                controller[act]
              else if Sirius.Utils.is_function(act)
                act
              else
                throw new Error("Action must be string or function");

    if !Sirius.Utils.is_function(@action) && !Sirius.Utils.is_string(@action)
      throw new Error("Action must be string or function")

    extract = (property, is_guard = false) =>
      p = params[property]
      k = controller["#{property}_#{act}"]
      err = (a) ->
        new Error("#{a} action must be string or function")

      if Sirius.Utils.is_string(p)
        t = controller[p]
        throw err(Sirius.Utils.camelize(property)) if !Sirius.Utils.is_function(t)
        t
      else if Sirius.Utils.is_function(p)
        p
      else if p
        throw err(Sirius.Utils.camelize(property))
      else if k
        throw err(Sirius.Utils.camelize(property)) if !Sirius.Utils.is_function(k)
        k
      else
        if !is_guard
          ->
        else
          null

    @before = extract('before')
    @after  = extract('after')
    @guard  = extract('guard', true)

    @data = params['data'] || null

  # @param e [EventObject|null] - event object if it's a mouse\key events, and `null` when it's url change event
  # @param args [Array<Any>] - arguments, used only for url changes events
  #
  # @note if you have a guard function, then firstly called it, if `guard` is true, then will be called `before`, `action` and `after` methods
  #
  handle_event: (e, args...) ->
    #when e defined it's a Event, otherwise it's call from url_routes
    if e
      data   = if Sirius.Utils.is_array(@data) then @data else if @data then [@data] else []
      data   = Sirius.Application.adapter.get_property(e, data)
      merge  = [].concat([], [e], data)
      if @guard
        if @guard.apply(null, merge)
          @before()
          @action.apply(null, merge)
          @after()
      else
        @before()
        @action.apply(null, merge)
        @after()
    else
      if @guard
        if @guard.apply(null, args)
          @before()
          @action.apply(null, args)
          @after()
      else
        @before()
        @action.apply(null, args)
        @after()

# @mixin
# @private
# Object, for creating event listeners
Sirius.RouteSystem =
  #
  # @param routes [Object] object with routes
  # @param fn [Function] callback, which will be called, after routes will be defined
  # @event application:hashchange - generate, when url change
  # @event application:404 - generate, if given url not matched with given routes
  # @event application:run - generate, after application running
  create: (routes, fn = ->) ->
    current = prev = window.location.hash

    for url, action of routes when url.indexOf("#") != 0 && url.toString() != "404"
      do (url, action) =>
        handler = if Sirius.Utils.is_function(action)
          action
        else
          (e) ->
            (new Sirius.ControlFlow(action)).handle_event(e)

        z = url.match(/^([a-zA-Z:]+)(\s+)?(.*)?/)
        event_name = z[1]
        selector   = z[3] || document #when it a custom event: 'custom:event' for example
        Sirius.Application.adapter.bind(selector, event_name, handler)

    # for cache change obj[k, v] to array [[k,v]]
    array_of_routes = for url, action of routes when url.toString() != "404"
      do (url, action) ->
        url    = new Sirius.RoutePart(url)
        action = if Sirius.Utils.is_function(action) then action else new Sirius.ControlFlow(action)
        [url, action]

    window.onhashchange = (e) =>
      prev = current
      current = window.location.hash
      result = false

      Sirius.Application.logger("Url change to: #{current}")
      Sirius.Application.adapter.fire(document, "application:hashchange", current, prev)

      #call first matched function
      for part in array_of_routes
        do(part) =>
          f = part[0]
          r = f.match(current)
          if r && !result
            result = true
            z = part[1]
            if z.handle_event
              z.handle_event(null, f.args)
            else
              z.apply(null, f.args)
            return

      #when no results, then call 404 or empty function
      if !result
        Sirius.Application.adapter.fire(document, "application:404", current, prev)
        #FIXME
        r404 = routes['404']
        if r404
          z = new Sirius.ControlFlow(r404)
          z.handle_event(null, current)

    fn()


#
# A main object, it's a start point all user applications
# @example
#   var routes = {
#     "#/"                : { controller : Controller, action: "action" },
#     "application: run"  : { controller : Controller, action: "run" },
#     "click #my-element" : { controller : Controller, action: "click_action"}
#   }
#   my_logger = function(msg) { console.log("Log: " + msg); }
#
#   Sirius.Application({ route : routes, logger: my_logger, log: true, start: "#/" });
#
Sirius.Application =
  # @property [Boolean] - when true, logs will be written
  log: false
  # @property [Adapter] - application adapter for javascript frameworks @see Adapter documentation
  adapter: null
  # @property [Boolean] - true, when application already running
  running: false
  # @property [Object] - user routes
  route: {}
  # @property [String] - a root url for application
  start : "#"
  # @method #logger(msg) - logger, default it's write message to console.log, may be redefined
  logger: (msg) ->
    return if !@log
    if window.console
      console.log msg
    else
      alert "Not supported `console`"
  #
  # @method #run(options)
  # @param options [Object] - base options for application
  run: (options = {}) ->
    @running = true
    @log     = options["log"]     || @log
    @adapter = options["adapter"] || throw new Error("Specify adapter")
    @route   = options["route"]   || @route
    @logger  = options["logger"]  || @logger
    @start    = options["start"]  || @start
    @logger("Logger enabled? #{@log}")
    n = @adapter.constructor.name
    @logger("Adapter: #{n}")

    # start
    Sirius.RouteSystem.create(@route, () =>
      @adapter.fire(document, "application:run", new Date());
    );

    if @start
      Sirius.redirect(@start)



