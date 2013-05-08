require 'json'
require 'bundler'

$stdout.sync = true

HEADER = {
  "Access-Control-Allow-Origin"  => "*",
  "Access-Control-Allow-Methods" => "POST",
  "Access-Control-Allow-Headers" => "Content-Type",
  "Content-Type"                 => "text/html"
}

port = lambda do |env|
  req = Rack::Request.new(env)
  puts "--> #{req.body.read}"
  [200, HEADER, %w(OK)]
end

run port
