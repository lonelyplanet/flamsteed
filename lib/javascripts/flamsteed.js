(function(window, undefined) {
  "use strict";

  window._FS = (function() {

    function fs(options) {
      options = options || {};
      this.version = {fs_version: "0.1"}
      this.url = options.url || "http://localhost:9876";
      this.log_max_size = options.log_max_size || 10;
      this.log_min_size = options.log_min_size || 3;
      this.log_max_interval = options.log_max_interval || 1500;
      this.debug = options.debug || false;
      this.sender = (options.strategy == "json") ? this._postJSON : this._appendImage;
      this.uuid = Math.random() * 100000000000000000;
      this.init(options.events);
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

    fs.prototype.log = function(data, nativeEvent) {
      if (this.isCapable()) {

        if (this.debug) {
          console.log("log:", data);
        }

        if (!this.isNowCapable() && !nativeEvent) {
          data.timestamp = this._performanceNowFallback(data.timestamp);
        }

        data.uuid = this.uuid

        this.buffer.push(data);
        this.flushIfFull();
        if (nativeEvent) { this.flush(); }
      }
    };

    fs.prototype.flushIfFull = function() {
      this.buffer.length >= this.log_max_size && this.flush();
    };

    fs.prototype.flushIfEnough = function() {
      this.buffer.length >= this.log_min_size && this.flush();
    };

    fs.prototype.flush = function() {
      if (!this.flushing) {
        if (this.debug) {
          console.log("flushing:", this.buffer);
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
      if (data.length > 0) {
        this.sender.call(this, data);
      }
    };

    // PRIVATE
    fs.prototype._appendImage = function(data) {
      var i = document.createElement('img');
      i.src = this.url + "?" + this._serialize(data);
      return document.body.appendChild(i);
    };

    // PRIVATE
    fs.prototype._postJSON = function(data) {
      var xhr = new window.XMLHttpRequest();
      xhr.open("post", this.url, true);
      xhr.send(JSON.stringify(data));
    };

    // PRIVATE
    fs.prototype._serialize = function(data) {
      var s = [],
        len = data.length;
      for (var key in data) {
        var obj = data[key];
        for (var prop in obj) {
          s[s.length] = encodeURIComponent(prop) + "=" + encodeURIComponent(obj[prop]);
        }
      }
      return s.join("&").replace(/%20/g, "+");
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
      var t = window.performance.timing;
      this.log({
        event: "ttfb",
        timestamp: t.responseStart
      });
      this.log({
        event: "startRender",
        timestamp: t.domLoading
      });

      window.addEventListener("DOMContentLoaded", this._logDomReadyAndFlush.bind(this));
      window.addEventListener("onload", this._logOnLoadAndFlush.bind(this));

      this.flush();
    };

    // PRIVATE
    fs.prototype._logDomReadyAndFlush = function() {
      this.log({
        event: 'domReady',
        timestamp: window.performance.timing.domComplete - window.performance.timing.navigationStart
      }, true);
    };

    // PRIVATE
    fs.prototype._logOnLoadAndFlush = function() {
      this.log({
        event: 'onload',
        timestamp: window.performance.timing.loadEventEnd - window.performance.timing.navigationStart
      }, true);
    };

    fs.prototype._performanceNowFallback = function(timestamp) {
      return timestamp - window.initialTimestamp;
    };

    fs.prototype.init = function(seedEvents) {
      this.emptyBuffer();
      this.resetTimer();
      if (seedEvents && seedEvents.length > 0) {
        seedEvents.push(this.version)
        this.log(seedEvents);
      } else {
        this.log(this.version);
      }

      window.addEventListener("unload", this.flush.bind(this));

      if (this.isRumCapable()) {
        this._initRum();
      };
    };

    return fs;
  })();
})(this);