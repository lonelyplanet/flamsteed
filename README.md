# flamsteed.js

flamsteed.js is a tiny, speedy, and modular client-side event logger.
RUM is built-in.

### Usage
    
    var fs = new _FS({
      url: "http://my.flamsteed.endpoint"  
    });
    
    fs.log({
        some: "data"
    });
    
flamsteed buffers logged events. The buffer is only flushed back to the
server (and logged events are sent) when:

* buffer size greater or equal to `log_min_size` and `max_log_interval` has passed
* buffer size greater or equal to `log_max_size`
* `unload` event is triggered when the visitor navigates away from
  the page

(TODO) When flamsteed first initializes, it generates a `uuid`. The `uuid` is
sent back with every bunch of events, so it can be used to identify
all the events associated with a particular page impression.

Each payload flushed back to the server looks like this:

    {
      uuid: "b57deb09-c6f5-4e0b-99a9-e0618d3b5711",
      timestamp: 1354880453288,
      data: [
        { some: "data" },
        { other: "thing", key: "val" },
        // snip
      ]
    }
    
### Options

* `log_max_interval`: polling interval

* `log_min_size`: smallest number of unsent logged events to send

* `log_max_size`: threshold of number of unsent logged events to
  trigger immediately sending

* `url`: url of server endpoint

### RUM (TODO)

There are two sources of real user monitoring data:

    `window.performance.timing`

    `chrome.loadTimes`
    
There are three events that force a flush of RUM data:

* "Operational" timings:
  TTFB (time to first byte received for the main document)
  StartRender (time to first non empty browser canvas)
  DocumentReady (time to fully build the dom)

* "Business" timings such as time-to-first-lodging are sent when `onload` fires
  OnLoad (time to fully download the last resource defined by the main document)

* Everything we have is sent when `unload` fires

The benefit of this approach is that as much data is sent as possible.

The downside is that, to get the full picture of a page impression,
the server-side has to associate all the timing information using the `uuid`.

### Goals

* speedy
* tiny
* modular

*Wide browser compatibility is not a current goal.*

## Development

    $ npm install
    $ bundle
    
One-shot test run:

    $ npm test

Continuous testing:

    $ guard
