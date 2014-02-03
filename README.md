# Ruby::Itach::Ip2ir

Unofficial - Ruby interface to Global Cache's itach ip2ir infrared emitter devices

## Installation

Add this line to your application's Gemfile:

    gem 'ruby-itach-ip2ir'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ruby-itach-ip2ir

## Usage

```ruby
require 'ruby-itach-ip2ir'
device = RubyItachIp2ir::Device.new("192.168.0.108")
device.connect

device.set_learning_mode(true)
device.listen_for_learning_responses{|resp| puts "send_ir_string = #{resp.inspect}" }
# send_ir_string = "sendir,1:3,6,37878,1,1,125,61,16,15,16,15...
device.set_learning_mode(false)

device.send_ir_raw(send_ir_string)

device.send_ir( device_id, request_id, freq, repeat, offset, ir_string )
device.send_ir( "1:3", :auto, 37878, 1, 1, "125,61,16,15,16,15..." )
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
