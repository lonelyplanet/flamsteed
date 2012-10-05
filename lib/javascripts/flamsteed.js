// flamsteed.js: client-side event logger

(function(window, undefined) {
     // TODO: wrap in feature-detecting conditional
     window._FS = (function() {            
                      function fs(options) {
                          if (options === null) options = {};
                          this.url               = options.url || "http://localhost:9876";
                          this.log_max_size      = options.log_max_size || 10;
                          this.log_min_size      = options.log_min_size || 3;
                          this.log_max_interval  = options.log_max_interval || 1500;
                          this.init();
                      };

                      fs.prototype.log = function(data) {
                          this.buffer.push(data);
                          this.flushIfFull();
                      };

                       fs.prototype.flushIfFull = function() {
                          if(this.buffer.length >= this.log_max_size) {
                              this.flush();
                          }
                      };

                      fs.prototype.flushIfEnough = function() {
                          if(this.buffer.length >= this.log_min_size) { 
                              this.flush(); 
                          }
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

                      fs.prototype.init = function() {
                          this.emptyBuffer();
                          this.resetTimer();
                      };
                      
                      return fs;
                  })();
}).call(this);
