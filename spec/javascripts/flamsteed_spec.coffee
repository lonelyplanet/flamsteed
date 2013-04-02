spec_helper = require("./support/spec_helper")
spec_helper.setupWindow()

describe "_FS", ()->
        fs   = undefined
        
        data             = "data"
        url              = "url"
        log_max_interval = "log max interval"
        serializeStub    = [{event: 'header', timestamp: '12345'},{event: 'footer', timestamp: '23456'}]
        timingStub       = {domComplete: 123, loadEventEnd: 234, domLoading: 345, responseStart: 456}
       

        beforeEach ()->
                window.performance = {timing: timingStub}
                fs = new window._FS({
                        url: url
                        log_max_interval: log_max_interval
                })

        it "has an URL", ()->
          expect(fs.url).toEqual("url")

        describe "constructor", ()->
                beforeEach ()->
                        spyOn(fs, "emptyBuffer")
                        spyOn(fs, "resetTimer")
                        spyOn(fs, "_initRum")

                it "empties the message buffer", ()->
                        fs.constructor()
                        expect(fs.emptyBuffer).toHaveBeenCalled()

                it "starts the timer", ()->
                        fs.constructor()
                        expect(fs.resetTimer).toHaveBeenCalled()

                it "starts the rum module", ()->
                        fs.constructor()
                        expect(fs._initRum).toHaveBeenCalled()


        describe "serialize", ->
          it "serializes an array of objects", ->
            output = fs._serialize(serializeStub)
            expect(output).toEqual('event=header&timestamp=12345&event=footer&timestamp=23456')


        describe "log", ()->
                it "checks whether the browser is capable", ()->
                        spyOn(fs, "isCapable")
                        fs.log()
                        expect(fs.isCapable).toHaveBeenCalled()
                
                describe "when the browser is capable", ()->
                        
                        beforeEach ()->
                                spyOn(fs, "isCapable").andReturn(true)
                                spyOn(fs, "flushIfFull")
                        
                        it "pushes the data onto the buffer", ()->
                                containing = new jasmine.Matchers.ObjectContaining({event: data});
                                fs.log(data)
                                expect(fs.buffer.length).toEqual(1)
                                expect(containing.jasmineMatches(fs.buffer[0], [], [])).toBe(true)

                        it "calls flushIfFull", ()->
                                fs.log()
                                expect(fs.flushIfFull).toHaveBeenCalled()

                describe "when the browser is not capable", ()->

                        beforeEach ()->
                                spyOn(fs, "isCapable").andReturn(false)
                                spyOn(fs, "flushIfFull")

                        it "does not push data onto the buffer", ()->
                                fs.log(data)
                                expect(fs.buffer).toEqual([])

                        it "does not call flushIfFull", ()->
                                fs.log()
                                expect(fs.flushIfFull).not.toHaveBeenCalled()
                                
        describe "flushIfFull", ()->
                beforeEach ()->
                        spyOn(fs, "flush")
                        fs.buffer = [data]

                describe "when the buffer is greater or equal to log_max_size", ()->
                        beforeEach ()->
                                fs.log_max_size = fs.buffer.length

                        it "flushes the buffer", ()->
                                fs.flushIfFull()
                                expect(fs.flush).toHaveBeenCalled()

                describe "when the buffer is less than log_max_size", ()->
                        beforeEach ()->
                                fs.log_max_size = fs.buffer.length + 1

                        it "flushes the buffer", ()->
                                fs.flushIfFull()
                                expect(fs.flush).not.toHaveBeenCalled()

        describe "flushIfEnough", ()->
                beforeEach ()->
                        spyOn(fs, "flush")
                        fs.buffer = [data]

                describe "when the buffer is greater or equal to log_min_size", ()->
                        beforeEach ()->
                                fs.log_min_size = fs.buffer.length

                        it "flushes the buffer", ()->
                                fs.flushIfEnough()
                                expect(fs.flush).toHaveBeenCalled()

                describe "when the buffer is less than log_min_size", ()->
                        beforeEach ()->
                                fs.log_min_size = fs.buffer.length + 1

                        it "flushes the buffer", ()->
                                fs.flushIfEnough()
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
                                
        # describe "sendData", ()->
        #         xhr = new Object({
        #                 open: ()->
        #                 send: ()->
        #         })
        #         
        #         beforeEach ()->
        #                 spyOn(window, "XMLHttpRequest").andReturn(xhr)
        #                 # FIXME: xhr = createSpyObj("xhr", ["open", "send"])
        #                 spyOn(xhr, "open")
        #                 spyOn(xhr, "send")
        #                         
        #         describe "when there is data to send", ()->
        #                 it "sends data as JSON to url and does not wait for response", ()->
        #                         fs.sendData([data])
        #                         expect(xhr.open).toHaveBeenCalledWith("post", url, true)
        #                         expect(xhr.send).toHaveBeenCalledWith(url, JSON.stringify([data]))

        describe "sendData", ->
          it "creates a 1x1 image ", ->
            image = fs._appendImage(url, "serialized+string")
            expect(image.length).not.toEqual(0)
            expect(image.getAttribute('src')).toContain(url)
            expect(image.getAttribute('src')).toContain("serialized+string")


        describe "resetTimer", ()->
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
                        spyOn(fs.startPoll, "bind").andReturn(bound_start_poll)

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
                        spyOn(fs.flushIfEnough, "bind").andReturn(bound_flush_if_enough)
                        spyOn(window, "setInterval")

                it "starts polling flushIfEnough", ()->
                        fs.startPoll()
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

          it "empties the buffer on init", ->
            fs._initRum()
            expect(fs.buffer.length).toEqual(2)
            expect(fs.flush).toHaveBeenCalled()
          
          it "flushes the buffer on domReady", ->
            event = document.createEvent("HTMLEvents");
            event.initEvent("DOMContentLoaded", true, true);
            window.dispatchEvent(event)
            expect(fs.flush).toHaveBeenCalled()
          
          it "flushes the buffer on onload", ->
            window.onload()
            expect(fs.flush).toHaveBeenCalled()
            
          it "flushes the buffer on unload", ->
            event = document.createEvent("HTMLEvents");
            event.initEvent("beforeunload", true, true);
            window.dispatchEvent(event)
            expect(fs.flush).toHaveBeenCalled()




