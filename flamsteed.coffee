class window.Flamsteed

        url: "http://localhost:9876"
        log_max_size: 10
        log_min_size:  3
        log_max_interval: 1500
        flush_immediately: true

        constructor: (options = {})->
                @setOptions(options)
                @init

        setOptions: (options)->
                @url = options.url || @url
                @log_max_interval = options.log_max_interval || @log_max_interval
                @log_min_size     = options.log_min_size     || @log_min_size
                @log_max_size     = options.log_max_size     || @log_max_size
                @flush_immediately = options.flush_immediately || @flush_immediately

        log: (data)->
                @buffer.push(data)
                if @flush_immediately and @buffer.length >= @log_max_size
                        @flush

        flushIfEnough: ()->
                if @buffer.length >= @log_min_size
                        @flush

        flush: ()->
                if not @flushing
                        @flushing = true
                        @resetTimer
                        @sendData(@buffer)
                        @emptyBuffer
                        @flushing = false

        sendData: (data)->
                if data.length > 0
                        xhr = new XMLHttpRequest()
                        xhr.send(@url, JSON.stringify(data))

        resetTimer: ()->
                clearInterval(@interval)
                clearTimeout(@timeout)
                f = =>
                        @interval = setInterval (do =>
                                @flushIfEnough), @log_max_interval
                @timeout = setTimeout (do =>
                        f), @log_max_interval

        emptyBuffer: ()->
                @buffer = []

        init: ()->
                @emptyBuffer
                console.log(@buffer)
                @resetTimer
