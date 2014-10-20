describe "_FS", ()->
  fs = undefined

  data             = {e: "test"}
  remoteUrl        = "url"
  session_id       = 987654321
  fid              = 123456789
  log_max_interval = "log max interval"
  serializeStub    = [{e: 'header', t: '12345'},{e: 'footer', t: '23456'}]
  timingStub       = {
    connectEnd: 1413220481973,
    connectStart: 1413220481960,
    domComplete: 1413220485058,
    domContentLoadedEventEnd: 1413220483270,
    domContentLoadedEventStart: 1413220483268,
    domInteractive: 1413220483268,
    domLoading: 1413220482230,
    domainLookupEnd: 1413220481960,
    domainLookupStart: 1413220481949,
    fetchStart: 1413220481947,
    loadEventEnd: 1413220485102,
    loadEventStart: 1413220485058,
    navigationStart: 1413220481947,
    redirectEnd: 0,
    redirectStart: 0,
    requestStart: 1413220481973,
    responseEnd: 1413220482002,
    responseStart: 1413220481991,
    secureConnectionStart: 0,
    unloadEventEnd: 0,
    unloadEventStart: 0 }


  beforeEach ()->
    window.performance = { timing: timingStub }
    fs = new window._FS({
      remoteUrl: remoteUrl,
      log_max_interval: log_max_interval,
      session_id: session_id,
      fid: fid
    })

  it "has a remote URL", ->
    expect(fs.remoteUrl).toEqual(remoteUrl)

  describe "session_id attribute", ->
    it "supports u option", ->
      fs = new window._FS({ u: session_id })
      expect(fs.session_id).toEqual(session_id)

    it "supports session_id option", ->
      expect(fs.session_id).toEqual(session_id)

    it "defaults value", ->
      fs = new window._FS()
      expect(fs.session_id).not.toBe(null)

  describe "fid attribute", ->
    it "supports fid option", ->
      expect(fs.fid).toEqual(fid)

    it "supports page_impression_id option", ->
      fs = new window._FS({ page_impression_id: fid })
      expect(fs.fid).toEqual(fid)

    describe "default value", ->
      beforeEach ()->
        spyOn(Date, "now").andReturn(123)
        fs = new window._FS({ session_id: session_id })

      it "utilises session_id value", ->
        expect(fs.fid.split('-')[0]).toEqual(session_id.toString())

      it "utilises Date", ->
        expect(fs.fid.split('-')[1]).toEqual(123.toString())

  describe "session_id attribute", ->
    it "supports schema option", ->
      fs = new window._FS({ schema: "0.3" })
      expect(fs.schema).toEqual("0.3")

    it "defaults value", ->
      fs = new window._FS()
      expect(fs.schema).toEqual("0.1")


  describe "constructor", ->
    beforeEach ->
      spyOn(fs, "emptyBuffer")
      spyOn(fs, "resetTimer")
      spyOn(fs, "isCapable").andReturn(true)
      spyOn(fs, "log")

    it "empties the message buffer", ->
      fs.constructor()
      expect(fs.emptyBuffer).toHaveBeenCalled()

    it "starts the timer", ->
      fs.constructor()
      expect(fs.resetTimer).toHaveBeenCalled()


  describe "serialize", ->
    it "serializes an array of objects", ->
      output = fs._serialize(serializeStub)
      expect(output).toEqual('[0][e]=header&[0][t]=12345&[1][e]=footer&[1][t]=23456')

    it "ensures missing values are nullified", ->
      output = fs._serialize([{ z: '', y: -1 }])
      expect(output).toEqual('[0][z]=null&[0][y]=-1')

    it "ensures spaces are escaped", ->
      output = fs._serialize([{ z: 'foo bar' }])
      expect(output).toEqual('[0][z]=foo+bar')

    it "ensures each event is distinct", ->
      output = fs._serialize([{ x: 'foo', t: 1 }, { y: 'bar', t: 2 }, { z: 'car', t: 3 }])
      expect(output).toEqual('[0][x]=foo&[0][t]=1&[1][y]=bar&[1][t]=2&[2][z]=car&[2][t]=3')

    it "escapes first level attributes", ()->
      output = fs._serialize([{ z: 'http://foo.com/test?abv=current' }])
      expect(output).toEqual('[0][z]=http%3A%2F%2Ffoo.com%2Ftest%3Fabv%3Dcurrent')

    it "escapes function buffer value", ()->
      fn = ->
        return { z: 'http://foo.com/test?abv=current' };
      output = fs._serialize([fn()])
      expect(output).toEqual('[0][z]=http%3A%2F%2Ffoo.com%2Ftest%3Fabv%3Dcurrent')


  describe "log", ()->
    it "checks whether the browser is capable", ->
      spyOn(fs, "isCapable")
      fs.log()
      expect(fs.isCapable).toHaveBeenCalled()

    describe "when the browser is capable", ->

      beforeEach ()->
        spyOn(fs, "isCapable").andReturn(true)
        spyOn(fs, "_flushIfFull")
        spyOn(fs.buffer, "push")
        spyOn(Date, 'now').andReturn(123)

      it "pushes the data onto the buffer", ->
        containsData = new jasmine.Matchers.ObjectContaining({ e: data.e });
        fs.log(data)
        expect(fs.buffer.push).toHaveBeenCalledWith(containsData)

      it "calls _flushIfFull", ()->
        fs.log(data)
        expect(fs._flushIfFull).toHaveBeenCalled()

      it "pushes session_id to the data", ()->
        containsData = new jasmine.Matchers.ObjectContaining({ session_id: session_id });
        fs.log(data)
        expect(fs.buffer.push).toHaveBeenCalledWith(containsData)

      it "pushes fid to the data", ()->
        containsData = new jasmine.Matchers.ObjectContaining({ fid: fid });
        fs.log(data)
        expect(fs.buffer.push).toHaveBeenCalledWith(containsData)

      it "pushes schema to the data", ()->
        containsData = new jasmine.Matchers.ObjectContaining({ schema: "0.1" });
        fs.log(data)
        expect(fs.buffer.push).toHaveBeenCalledWith(containsData)

      it "pushes t to the data", ()->
        containsData = new jasmine.Matchers.ObjectContaining({ t: 123 });
        fs.log(data)
        expect(fs.buffer.push).toHaveBeenCalledWith(containsData)

      it "pushes t to the data when existing value is empty", ()->
        containsData = new jasmine.Matchers.ObjectContaining({ t: 123 });
        data.t = ''
        fs.log(data)
        expect(fs.buffer.push).toHaveBeenCalledWith(containsData)

      it "skips t assignment when present", ()->
        new_data = { e: data.e, t: 987 }
        containsData = new jasmine.Matchers.ObjectContaining({ t: 987 });
        fs.log(new_data)
        expect(fs.buffer.push).toHaveBeenCalledWith(containsData)


    describe "when the browser is not capable", ()->

      beforeEach ()->
        spyOn(fs, "isCapable").andReturn(false)
        spyOn(fs, "_flushIfFull")

      it "does not push data onto the buffer", ()->
        fs.log(data)
        expect(fs.buffer).toEqual([])

      it "does not call _flushIfFull", ()->
        fs.log()
        expect(fs._flushIfFull).not.toHaveBeenCalled()


  describe "time", ()->

    beforeEach ()->
      spyOn(fs, "log")

    it "is an alias for #log", ->
      fs.time(data)
      expect(fs.log).toHaveBeenCalledWith(data)


  describe "_flushIfFull", ()->
    beforeEach ()->
      spyOn(fs, "flush")
      fs.buffer = [data]

    describe "when the buffer is greater or equal to log_max_size", ()->
      beforeEach ()->
        fs.log_max_size = fs.buffer.length

      it "flushes the buffer", ()->
        fs._flushIfFull()
        expect(fs.flush).toHaveBeenCalled()

    describe "when the buffer is less than log_max_size", ()->
      beforeEach ()->
        fs.log_max_size = fs.buffer.length + 1

      it "flushes the buffer", ()->
        fs._flushIfFull()
        expect(fs.flush).not.toHaveBeenCalled()


  describe "flushIfEnough", ()->
    beforeEach ()->
      spyOn(fs, "flush")
      fs.buffer = [data]

    describe "when the buffer is greater or equal to log_min_size", ()->
      beforeEach ()->
        fs.log_min_size = fs.buffer.length

      it "flushes the buffer", ()->
        fs._flushIfEnough()
        expect(fs.flush).toHaveBeenCalled()

    describe "when the buffer is less than log_min_size", ()->
      beforeEach ()->
        fs.log_min_size = fs.buffer.length + 1

      it "flushes the buffer", ()->
        fs._flushIfEnough()
        expect(fs.flush).not.toHaveBeenCalled()


  describe "flush", ()->
    beforeEach ()->
      spyOn(fs, "resetTimer")
      spyOn(fs, "_sendData")
      spyOn(fs, "emptyBuffer")

    describe "when already flushing", ()->
      beforeEach ()->
        fs.flushing = true

      it "does not send any data", ()->
        fs.flush()
        expect(fs._sendData).not.toHaveBeenCalled()

    describe "buffer empty", ()->

      it "does not send any data", ()->
        fs.flush()
        expect(fs._sendData).not.toHaveBeenCalled()

    describe "when not already flushing", ()->
      beforeEach ()->
        fs.buffer = [data]

      it "resets the timer", ()->
        fs.flush()
        expect(fs.resetTimer).toHaveBeenCalled()

      it "calls sendData with the contents of the buffer", ()->
        contents_of_buffer = fs.buffer
        fs.flush()
        expect(fs._sendData).toHaveBeenCalledWith(contents_of_buffer)

      it "empties the buffer", ()->
        fs.flush()
        expect(fs.emptyBuffer).toHaveBeenCalled()


  describe "sendData", ->
    it "serializes and creates a 1x1 image ", ->
      image = fs._appendImage([{e: 'data'}])
      expect(image.length).not.toEqual(0)
      expect(image.style.visibility).toBe 'hidden'
      expect(image.getAttribute('src')).toContain(remoteUrl)
      expect(image.getAttribute('src')).toContain("[0][e]=data")


  describe "Tidying up", ->

    it "tidies when image present", ->
      fs.image = { parentNode: { removeChild: -> {} } }
      spyOn(fs.image.parentNode, 'removeChild')
      expect(fs._tidyUp()).toEqual(true)
      expect(fs.image.parentNode.removeChild).toHaveBeenCalledWith(fs.image)

    it "skips when image not present", ->
      expect(fs._tidyUp()).toEqual(false)


  describe "resetTimer", ->
    timeout  = "timeout"
    interval = "interval"
    bound_start_poll = "bound_start_poll"

    beforeEach ()->
      fs.timeout          = timeout
      fs.interval         = interval
      fs.log_max_interval = log_max_interval
      spyOn(window, "clearInterval")
      spyOn(window, "clearTimeout")
      spyOn(window, "setTimeout")
      spyOn(fs._startPoll, "bind").andReturn(bound_start_poll)

    it "clears the interval and timeout", ()->
      fs.resetTimer()
      expect(window.clearInterval).toHaveBeenCalledWith(interval)
      expect(window.clearTimeout).toHaveBeenCalledWith(timeout)

    it "starts polling every log_max_interval", ()->
      fs.resetTimer()
      expect(window.setTimeout).toHaveBeenCalledWith(bound_start_poll, log_max_interval)

  describe "startPoll", ()->
    bound_flush_if_enough = "bound_flush_if_enough"

    beforeEach ()->
      spyOn(fs._flushIfEnough, "bind").andReturn(bound_flush_if_enough)
      spyOn(window, "setInterval")

    it "starts polling flushIfEnough", ()->
      fs._startPoll()
      expect(window.setInterval).toHaveBeenCalledWith(bound_flush_if_enough, log_max_interval)

  describe "emptyBuffer", ()->
    beforeEach ()->
      fs.buffer = [data]

    it "empties the buffer", ()->
      fs.emptyBuffer()
      expect(fs.buffer).toEqual([])


  describe "RUM", ()->
    beforeEach ()->
      spyOn(fs, "flush")

    it "flushes the buffer on unload", ->
      containsPerf = new jasmine.Matchers.ObjectContaining(timingStub);
      fs._logRumAndFlush()
      expect(containsPerf.jasmineMatches(fs.buffer[0], [], [])).toBe(true)
      expect(fs.flush).toHaveBeenCalled()


  describe "now", ->

    describe "Date.now() unavailable", ->

      beforeEach ->
        spyOn(Date, "now").andReturn(undefined)
        spyOn(Date.prototype, "getTime").andReturn(987)

      it "returns epoch", ->
        expect(fs.now()).toBe(987)

    describe "Date.now() available", ->

      beforeEach ->
        spyOn(Date, "now").andReturn(123)

      it "returns epoch", ->
        expect(fs.now()).toEqual(123)
        expect(Date.now).toHaveBeenCalled()
