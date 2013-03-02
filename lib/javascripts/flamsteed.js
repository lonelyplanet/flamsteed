(function(window, undefined) {
  "use strict";

  window._FS = (function() {

    function fs(options) {
      options = options || {};
      this.url              = options.url || "http://localhost:9876";      
      this.log_max_size     = options.log_max_size || 10;
      this.log_min_size     = options.log_min_size || 3;
      this.log_max_interval = options.log_max_interval || 1500;
      this.debug            = options.debug || false;
      switch(options.strategy) {
      case "pixel":
        this.sender = this._appendImage;
      default:
        this.sender = this._postJSON;
      }
      this.init(options.events);
    }

    fs.prototype.isCapable = function() {
      return !!(Function.prototype.bind && document.addEventListener);
    };

    fs.prototype.isRumCapable = function() {
      return !!(window.performance && window.performance.timing);
    };
    
    fs.prototype.log = function(data) {
      if(this.debug) {
        console.log("log:", data);
      };
      if(this.isCapable()) {
        this.buffer.push(data);
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
        if(this.debug) {
          console.log(new Date().getTime(), "flushing:", this.buffer);
        }
        this.flushing = true;
        this.resetTimer(this);
        this._sendData(this.buffer);
        this.emptyBuffer();
        this.flushing = false;
      }
    };

    // PRIVATE
    fs.prototype._sendData = function(data) {
      if(data.length > 0) {
        this.sender.call(this, data);
      }
    };

    // PRIVATE
    fs.prototype._appendImage = function(data) {
      var i = document.createElement('img');
      i.src = this.url + "?" + this._serialize(data);
      document.body.appendChild(i);
    };

    // PRIVATE
    fs.prototype._postJSON = function(data) {
      // var xhr = new window.XMLHttpRequest();
      // xhr.open("post", this.url, true);
      // xhr.send(JSON.stringify(data));
    };

    // PRIVATE
    fs.prototype._serialize = function(data) {
      var s = [], len = data.length;
      for (var key in data) {
        var obj = data[key];
        for (var prop in obj) {
          s[s.length] = encodeURIComponent(prop) + "=" + encodeURIComponent(obj[prop]);
        }
      }
      return s.join("&").replace(/%20/g , "+"); 
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
    
    // PRIVATE
    fs.prototype._initRum = function() {
      var t   = window.performance.timing;
      this.t0 = t.navigationStart;
      this.log({ e: "responseStart", v: t.responseStart - this.t0 });
      this.log({ e: "domLoading", v: t.domLoading - this.t0 });
      
      // NOTE: no point in waiting for an event if already reached
      // this point in sequence. I think there's still a race
      // condition :(
      if (t.domComplete == 0) {
        window.addEventListener("load", this._logDomComplete.bind(this));
      } else {
        this._logDomComplete();
      }
      if (t.loadEventEnd == 0) {
        window.addEventListener("load", this._logLoadEventEnd.bind(this));
      } else {
        this._logLoadEventEnd();
      }

      this.flush();
    };    

    // PRIVATE
    fs.prototype._logDomComplete = function() {
      this.log({ e: 'domComplete', v: window.performance.timing.domComplete - this.t0 });
    };

    // PRIVATE
    fs.prototype._logLoadEventEnd = function() {
      this.log({ e: 'loadEventEnd', v: window.performance.timing.loadEventEnd - this.t0 });
    };

    fs.prototype.init = function(seedEvents) {
      this.emptyBuffer();
      this.resetTimer();
      if(seedEvents && seedEvents.length > 0) {
        this.log(seedEvents);
      }

      window.addEventListener("unload", this.flush.bind(this));

      if(this.isRumCapable()) {
        this._initRum();
      };
    };
    
    return fs;
  })();
})(this);
