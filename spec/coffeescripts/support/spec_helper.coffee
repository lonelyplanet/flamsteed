# There's an issue where PhantomJS doesn't have the `bind()` function: https://github.com/ariya/phantomjs/issues/10522
unless Function::bind
  Function::bind = (oThis) ->
    
    # closest thing possible to the ECMAScript 5 internal IsCallable function
    throw new TypeError("Function.prototype.bind - what is trying to be bound is not callable")  if typeof this isnt "function"
    aArgs = Array::slice.call(arguments, 1)
    fToBind = this
    fNOP = ->

    fBound = ->
      fToBind.apply (if this instanceof fNOP and oThis then this else oThis), aArgs.concat(Array::slice.call(arguments))

    fNOP:: = @::
    fBound:: = new fNOP()
    fBound