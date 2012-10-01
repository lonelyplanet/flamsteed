# flamsteed

flamsteed is a simple event-logging pipeline. Use it for RUM
(real-user monitoring) and click-tracking.

There are 3 components:

* flamsteed.js: client-side event logger
* TODO: flamsteed.conf: nginx conf for a flamsteed.js endpoint. It
  supplements each incoming event with additional info, and writes to
  a queue
* TODO: flamsteed.rb: ruby daemon to work off the queue of events (based on Sidekiq)

Requirements:

* Redis
* nginx compiled with the redis module[?]

## flamsteed.js

flamsteed is a tiny, speedy, and modular client-side event logger.

### Usage
    
    var fs = new _FS({
      url: "http://my.flamsteed.endpoint"  
    });
    
    fs.log({
        some: "data"
    });
    
flamsteed buffers logged events, and only sends logged events when
events in buffer either:

* greater or equal to `log_min_size` and `max_log_interval` has passed
* greater or equal to `log_max_size`
    
### Options

* `log_max_interval`: polling interval

* `log_min_size`: smallest number of unsent logged events to send

* `log_max_size`: threshold of number of unsent logged events to
  trigger immediately sending

### Goals

* speedy
* tiny
* modular

*Wide browser compatibility is not a current goal.*

#### Compatibility

__TODO__

## Development

    $ npm install
    $ bundle
    
One-shot test run:

    $ npm test

Continuous testing:

    $ guard
