
class Sirius.Internal.CacheHandlerProperty
  constructor: (@from_element, @watch_for, @event, @handler, @observer, @config) ->

  is_observer: () -> @observer != null
  is_listener: () -> !@is_observer

Sirius.Internal.CacheObserverHandlers =
  _handlers: []
  add_new_observer: (from_element, watch_for, handler, observer, config) ->
    p = new Sirius.Internal.CacheHandlerProperty(from_element, watch_for, null,
      handler, observer, config)
    @_handlers.push(p)

  add_new_bind_event: (from_element, watch_for, event, handler) ->
    p = new Sirius.Internal.CacheHandlerProperty(from_element, watch_for, event, handler, null)
    @_handlers.push(p)

  find_by_element: (e) ->
    @_handlers.filter (h) -> h.from_element == e

  find_by_element_and_watch_for: (e, w) ->
    @_handlers.filter (h) -> h.from_element == e && h.watch_for == w

  find_by_element_watch_for_and_event: (e, w, ev) ->
    @_handlers.filter (h) -> h.from_element == e && h.watch_for == w && h.event == ev

# hacks for observer when property or text changed into DOM

# @class
# describe changes from events
class Sirius.AbstractChangesResult
  constructor: () ->

  # @private
  @build: (object) ->
    from = object.from
    target = object.element
    if object['state']?
      return new Sirius.StateChanges(object.state, from, target)
    if object['attribute']?
      return new Sirius.AttributeChanges(object.text, object.attribute, from, target)
    return new Sirius.TextChanges(object.text, from, target)


# @class
# changes from input/textarea
class Sirius.TextChanges extends Sirius.AbstractChangesResult
  constructor: (@text, @from, @target) ->
    super()

class Sirius.AttributeChanges extends Sirius.AbstractChangesResult
  constructor: (@text, @attribute, @from, @target) ->
    super()
# @class
# changes from selector or input checkbox/radio elements
class Sirius.StateChanges extends Sirius.AbstractChangesResult
  constructor: (@state, @from, @target) ->
    super()

# @class
# @private
# events observer, it produces changes for materializing
class Sirius.Internal.Observer

  MO = window.MutationObserver ||
       window.WebKitMutationObserver ||
       window.MozMutationObserver || null

  INPUT_LIKE_TAGS = ["INPUT", "TEXTAREA", "SELECT"]
  BOOL_TYPES = ["checkbox", "radio"]
  OPTION = "OPTION"

  @Ev =
    input: "input"
    selectionchange: "selectionchange"
    childList: "childList"
    change: "change"
    DOMNodeInserted: "DOMNodeInserted"
    focusout: "focusout"
    focusin: "focusin"
    DOMAttrModified: "DOMAttrModified"


  @TextEvents = [@Ev.input, @Ev.childList,
                 @Ev.DOMNodeInserted,
                 @Ev.selectionchange]

  @is_text_event: (e) -> @TextEvents.indexOf(e.type) != -1
  @is_focus_event: (e) -> [@Ev.focusin, @Ev.focusout].indexOf(e.type) != -1


  # browser support: http://caniuse.com/#feat=mutationobserver
  # MutationObserver support in FF and Chrome, but in old ie (9-10) not
  # for support this browser
  # http://www.w3.org/TR/DOM-Level-2-Events/events.html#Events-MutationEvent
  # https://dvcs.w3.org/hg/domcore/raw-file/tip/Overview.html#mutation-observers
  # BUG when reset input, bound element should reset
  #
  # @example
  #
  #   new Sirius.Internal.Observer("#id input[name='email']", "input[name='email']", "text")
  #
  #
  constructor: (@from_element, @watch_for, @clb = ->) ->
    adapter = Sirius.Application.get_adapter()
    adapter.and_then(@_create)

  # @nodoc
  # @private
  _create: (adapter) =>
    logger  = Sirius.Application.get_logger(@constructor.name)
    clb  = @clb
    from = @from_element
    current_value = null
    watch_for = @watch_for

    tag  = adapter.get_attr(from, 'tagName')
    type = adapter.get_attr(from, 'type')

    logger.debug("Create binding for #{from}")

    O = Sirius.Internal.Observer

    # base callback
    handler = (e) ->
      logger.debug("Handler Function: given #{e.type} event")
      result = {text: null, attribute: null, from: from, element: e.target}
      return if O.is_focus_event(e)
      txt = adapter.text(from)

      if [O.Ev.input, O.Ev.selectionchange].indexOf(e.type) != -1 && txt == current_value
        return # no changes here

      if O.is_text_event(e)
        result.text = txt
        current_value = txt

      if e.type == O.Ev.change # get a state for input enable or disable
        result.state = adapter.get_attr(from, 'checked')

      if e.type == "attributes"
        attr_name = e.attributeName
        old_attr = e.oldValue || [] # FIXME remove this, because not used
        new_attr  = adapter.get_attr(from, attr_name)

        result.text = new_attr
        result.attribute = attr_name
        result.previous = old_attr

      if e.type == O.Ev.DOMAttrModified # for ie 9...
        attr_name = e.originalEvent.attrName
        old_attr  = e.originalEvent.prevValue
        new_attr  = adapter.get_attr(from, attr_name)
        result.text = new_attr
        result.attribute = attr_name
        result.previous = old_attr

      clb(Sirius.AbstractChangesResult.build(result))

    # how to handle

    if watch_for == Sirius.Internal.DefaultProperty
      # text + input

      if INPUT_LIKE_TAGS.indexOf(tag) != -1
        logger.debug("It is not a #{INPUT_LIKE_TAGS}")
        if BOOL_TYPES.indexOf(type) != -1 || tag == OPTION
          logger.debug("Get a #{type} & #{tag} element for bool elements")
          adapter.bind(document, from, O.Ev.change, handler)
          Sirius.Internal.CacheObserverHandlers.add_new_bind_event(from, watch_for,
            O.Ev.change, handler)
        else
          current_value = adapter.text(from)
          adapter.bind(document, from, O.Ev.input, handler)
          Sirius.Internal.CacheObserverHandlers.add_new_bind_event(from, watch_for,
            O.Ev.input, handler)
          #instead of using input event, which not work correctly in ie9
          #use own implementation of input event for form
          if Sirius.Utils.is_ie9()
            logger.warn("Hook for work with IE9 browser")
            adapter.bind(document, from, O.Ev.selectionchange, handler)
            Sirius.Internal.CacheObserverHandlers.add_new_bind_event(from, watch_for,
              O.Ev.selectionchange, handler)

        # return, because for input element seems this events enough

      else
        logger.warn("Seems you try to bind for #{tag} of #{type} for 'text' which is not supported")


    else if MO # any element + not text
      logger.debug("MutationObserver support")
      observer = new MO( (mutations) ->
        mutations.forEach handler
      )

      cnf =
        childList: true
        attributes: true
        characterData: true
        attributeOldValue: true
        characterDataOldValue: true
        subtree: false # FIXME subtree: true

      element = adapter.get(from) # fixme : all
      observer.observe(element, cnf)
      Sirius.Internal.CacheObserverHandlers.add_new_observer(from, watch_for, handler,
        observer, cnf)

    else # when null, need register event with routes
      # FIXME stackoverflow
      logger.warn("MutationObserver not supported")
      logger.warn("Use Deprecated events for observe")
      adapter.bind(document, from, O.Ev.DOMNodeInserted, handler)
      adapter.bind(document, from, O.Ev.DOMAttrModified, handler)
      Sirius.Internal.CacheObserverHandlers.add_new_bind_event(from, watch_for,
        O.Ev.DOMNodeInserted, handler)
      Sirius.Internal.CacheObserverHandlers.add_new_bind_event(from, watch_for,
        O.Ev.DOMAttrModified, handler)













