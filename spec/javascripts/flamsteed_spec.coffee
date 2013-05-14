spec_helper = require("./support/spec_helper")
spec_helper.setupWindow()

describe "_FS", ()->
  fs   = undefined

  data             = {e: "test"}
  remoteUrl        = "url"
  uuid             = {uuid: 123456789}
  log_max_interval = "log max interval"
  serializeStub    = [{e: 'header', t: '12345'},{e: 'footer', t: '23456'}]
  timingStub       = {domComplete: 123, loadEventEnd: 234, domLoading: 345, responseStart: 456, navigationStart: 100}


  beforeEach ()->
    window.performance = {timing: timingStub}
    fs = new window._FS({
      remoteUrl: remoteUrl
      log_max_interval: log_max_interval
      uuid: uuid
    })

  it "has a remote URL", ->
    expect(fs.remoteUrl).toEqual(remoteUrl)


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
      expect(output).toEqual('e=header&t=12345&e=footer&t=23456')


  describe "log", ()->
    it "checks whether the browser is capable", ->
      spyOn(fs, "isCapable")
      fs.log()
      expect(fs.isCapable).toHaveBeenCalled()
    
    describe "when the browser is capable", ->
      
      beforeEach ()->
        spyOn(fs, "isCapable").andReturn(true)
        spyOn(fs, "_flushIfFull")
      
      it "pushes the data onto the buffer", ->
        containsData = new jasmine.Matchers.ObjectContaining({e: data.e});
        fs.log(data)
        expect(fs.buffer.length).toEqual(1)
        expect(containsData.jasmineMatches(fs.buffer[0], [], [])).toBe(true)

      it "calls _flushIfFull", ()->
        fs.log(data)
        expect(fs._flushIfFull).toHaveBeenCalled()

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
    it "checks whether the browser is capable", ->
      spyOn(fs, "isNowCapable")
      fs.time()
      expect(fs.isNowCapable).toHaveBeenCalled()

    describe "when the browser is capable", ->
      
      beforeEach ()->
        window.performance.now = -> "200"
        spyOn(fs, "isNowCapable").andReturn(true)
        spyOn(fs, "log")

      it "logs the data", ->
        fs.time(data)
        expect(fs.log).toHaveBeenCalled()

      it "creates a timestamp", ->
        fs.time(data)
        expect(fs.log).toHaveBeenCalledWith({e: "test", t: "200"})

    describe "when the browser is not capable", ->
      beforeEach ()->
        spyOn(fs, "isNowCapable").andReturn(false)
        spyOn(fs, "log")

      it "logs the data", ->
        fs.time(data)
        expect(fs.log).not.toHaveBeenCalled()


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
      fs.buffer = [data]
      spyOn(fs, "resetTimer")
      spyOn(fs, "_sendData")
      spyOn(fs, "emptyBuffer")

    describe "when already flushing", ()->
      beforeEach ()->
        fs.flushing = true

      it "does not send any data", ()->
        fs.flush()
        expect(fs._sendData).not.toHaveBeenCalled()

    describe "when not already flushing", ()->
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
      expect(image.getAttribute('src')).toContain("e=data")


  describe "Tidying up", ->
    beforeEach ->
      spyOn(fs, '_tidyUp')

    it "tidies after sending the data", ->
      fs.flush()
      expect(fs._tidyUp).toHaveBeenCalled()


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
      containsPerf = new jasmine.Matchers.ObjectContaining({domComplete: timingStub.domComplete - timingStub.navigationStart});
      fs._logRumAndFlush()
      expect(containsPerf.jasmineMatches(fs.buffer[0], [], [])).toBe(true)
      expect(fs.flush).toHaveBeenCalled()
