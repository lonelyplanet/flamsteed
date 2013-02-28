(function(window, undefined) {
  window._FS = (function() {

    function fs(options, startBuffer) {
      options = options || {};
      this.url               = options.url || "http://localhost:9876";
      this.log_max_size      = options.log_max_size || 10;
      this.log_min_size      = options.log_min_size || 3;
      this.log_max_interval  = options.log_max_interval || 1500;
      this.init(startBuffer);
    }

    fs.prototype.isCapable = function() {
      return !!Function.prototype.bind && window.performance.timing && document.addEventListener;
    };
    
    fs.prototype.serialize = function(data) {
      var s = [], len = data.length;
      for (var key in data) {
        var obj = data[key];
        for (var prop in obj) {
          s[s.length] = encodeURIComponent( prop ) + "=" + encodeURIComponent( obj[prop] );
         }
      }
      return s.join( "&" ).replace(/%20/g , "+"); 
    };

    fs.prototype.log = function(data) {
        if(this.isCapable()) {
            this.buffer.push(
              {
                event: data
              }
            );
            this.flushIfFull();
        }
    };

    fs.prototype.flushIfFull = function() {
        this.buffer.length >= this.log_max_size && this.flush();
    };

    fs.prototype.flushIfEnough = function() {
        this.buffer.length >= this.log_min_size && this.flush();
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
    
    fs.prototype.createImage = function (path, params) {
      i = document.createElement('img');
      i.src = path + "?" + params;
      return i;
    };

    fs.prototype.sendData = function(data) {
        
        if(data.length > 0) {
          this.createImage(this.url, this.serialize(data))
          document.body.appendChild(i);
          
          /* var xhr = new window.XMLHttpRequest();
          xhr.open("post", this.url, true);
          xhr.send(this.url, JSON.stringify(data));
          */
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
    
    fs.prototype.startRum = function() {
      // t = window.performance.timing;
      // this.buffer.push({event: "ttfb", timestamp: t.responseStart})
      // this.buffer.push({event: "startRender", timestamp: t.domLoading})
      this.flush()
    };
    
    fs.prototype.addHandlers = function(that) {
      document.addEventListener("DOMContentLoaded", function(){
        that.buffer.push({event: 'domReady', timestamp: window.performance.timing.domComplete});
        that.flush()
      }, false);
      window.onload = function(){
        that.buffer.push({event: 'onload', timestamp: window.performance.timing.loadEventEnd});
        that.flush()
      };
      window.addEventListener("beforeunload", function(){
        that.flush()
      }, false);
    }

    fs.prototype.init = function(startBuffer) {
        this.emptyBuffer();
        this.resetTimer();
        this.buffer = startBuffer || [];
        this.startRum()
        this.addHandlers(this)
    };

    return fs;

  })();
})(this);

