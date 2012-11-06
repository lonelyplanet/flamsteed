(function(window, undefined) {
  window._FS = (function() {

    function fs(options, startBuffer) {
      options = options || {};
      this.url               = options.url || "http://localhost:9876";
      this.log_max_size      = options.log_max_size || 10;
      this.log_min_size      = options.log_min_size || 3;
      this.log_max_interval  = options.log_max_interval || 1500;
      this.capable = !!Function.prototype.bind && window.hasOwnProperty('JSON') && window.hasOwnProperty('XMLHttpRequest');
      this.capable && this.init(startBuffer);
    }

    fs.prototype.log = function(data) {
      try {
        this.buffer.push({event: data, timestamp: new Date().getTime()});
        this.flushIfFull();
      } catch (e) {
        return "Flamsteed not supported";
      }
    };

    fs.prototype.flushIfFull = function() {
        this.buffer.length >= this.log_max_size && this.flush()
    };

    fs.prototype.flushIfEnough = function() {
        this.buffer.length >= this.log_min_size && this.flush()
    };

    fs.prototype.flush = function() {
        if(!this.flushing) {
            this.flushing = true;
            this.resetTimer(this);
            this.sendData(this.buffer);
            this.emptyBuffer();
            this.flushing = false;
        }
    };
    
    fs.prototype.sendData = function(data) {
        if(data.length > 0) {
            var xhr = new window.XMLHttpRequest();
            xhr.open("post", this.url, true);
            xhr.send(this.url, JSON.stringify(data));
        }
    };

    fs.prototype.resetTimer = function() {
        window.clearInterval(this.interval);
        window.clearTimeout(this.timeout);
        this.timeout = window.setTimeout(this.startPoll.bind(this), this.log_max_interval);
    };

     fs.prototype.startPoll = function() {
         this.interval = window.setInterval(this.flushIfEnough.bind(this), this.log_max_interval);
     };

    fs.prototype.emptyBuffer = function() {
        this.buffer = [];
    };

    fs.prototype.init = function(startBuffer) {
        this.emptyBuffer();
        this.resetTimer();
        this.buffer = startBuffer || [];
        this.buffer.push(window.performance.timing);
    };
    
    return fs;

  })();
})(this);

