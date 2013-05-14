(function(window, undefined) {
  "use strict";

  window._FS = (function() {

    function fs(options) {
      options = options || {};
      this.remoteUrl = options.remoteUrl || "http://localhost:4567";
      this.log_max_size = options.log_max_size || 10;
      this.log_min_size = options.log_min_size || 3;
      this.log_max_interval = options.log_max_interval || 1500;
      this.debug = options.debug || false;
      this.u = options.u || {u: Math.random() * 100000000000000000};
      this._init(options.events);
    }

    fs.prototype.isCapable = function() {
      return !!(Function.prototype.bind && document.addEventListener);
    };

    fs.prototype.isRumCapable = function() {
      return !!(window.performance.timing || window.msPerformance || window.webkitPerformance || window.mozPerformance);
    };

    fs.prototype.isNowCapable = function() {
      return !!window.performance.now;
    };

    fs.prototype.emptyBuffer = function() {
      this.buffer = [];
    };

    fs.prototype.log = function(data) {
      if (this.isCapable()) {
        this.debug && console.log("log:", data);
        this.buffer.push(data);
        this._flushIfFull();
      }
    };

    fs.prototype.time = function(data) {
      if (this.isNowCapable()) {
        data.t = window.performance.now()
        this.log(data);
      }
    };
    
    fs.prototype.flush = function() {
      if (!this.flushing) {
        this.debug && console.log("flushing:", this.buffer);
        this.flushing = true;
        this.resetTimer(this);
        this.buffer.push(this.uuid)
        this._sendData(this.buffer);
        this.emptyBuffer();
        this._tidyUp()
        this.flushing = false;
      }
    };

    fs.prototype.resetTimer = function() {
      window.clearInterval(this.interval);
      window.clearTimeout(this.timeout);
      this.timeout = window.setTimeout(this._startPoll.bind(this), this.log_max_interval);
    };

    // PRIVATE
    fs.prototype._flushIfFull = function() {
      this.buffer.length >= this.log_max_size && this.flush();
    };
    
    // PRIVATE
    fs.prototype._flushIfEnough = function() {
      this.buffer.length >= this.log_min_size && this.flush();
    };

    // PRIVATE
    fs.prototype._sendData = function(data) {
      if (data.length > 0) {
        this._appendImage.call(this, data);
      }
    };

    // PRIVATE
    fs.prototype._appendImage = function(data) {
      this.image = document.createElement('img');
      this.image.style.visibility = "hidden";
      this.image.src = this.remoteUrl + "?" + this._serialize(data);
      return document.body.appendChild(this.image);
    };

    // PRIVATE
    fs.prototype._tidyUp = function() {
      this.image.parentNode && this.image.parentNode.removeChild(this.image);
    }

    // PRIVATE
    fs.prototype._serialize = function(data) {
      var s = [], key, prop, obj, len = data.length;
      for (key in data) {
        obj = data[key];
        for (prop in obj) {
          s[s.length] = encodeURIComponent(prop) + "=" + encodeURIComponent(obj[prop]);
        }
      }
      return s.join("&").replace(/%20/g, "+");
    };

    // PRIVATE
    fs.prototype._startPoll = function() {
      this.interval = window.setInterval(this._flushIfEnough.bind(this), this.log_max_interval);
    };

    // PRIVATE
    fs.prototype._processRum = function() {
      var t = window.performance.timing, n = t.navigationStart, prop, perf = {};
      for (prop in t) {
        perf[prop] = (t[prop] >= n) ? t[prop] - n : t[prop];
      }
      return perf;
    }

    // PRIVATE
    fs.prototype._logRumAndFlush = function() {
      this.log(this._processRum(), true);
      this.flush();
    };

    // PRIVATE
    fs.prototype._init = function(seedEvents) {
      this.emptyBuffer();
      this.resetTimer();
      if (seedEvents && seedEvents.length > 0) {
        seedEvents[0]['event']['fs_version'] = this.version
        seedEvents.map(function(e){
          this.log(e)
        }, this);
      } else {
        this.log({fs_version: this.version});
      }
      if (this.isRumCapable()) {
        window.addEventListener("unload", this._logRumAndFlush.bind(this));
      };
      this.flush()
    };

    return fs;
  })();
})(this);