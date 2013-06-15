=begin
require 'ruby-itach-ip2ir'
device = RubyItachIp2ir::Device.new("192.168.0.108")
device.connect
device.set_learning_mode(true)
device.listen_for_learning_responses{|resp| puts "> #{resp.inspect}" }

=end

require "socket"

class RubyItachIp2ir::Device
  attr_accessor :ip
  attr_accessor :socket

  def initialize(ip)
    self.ip = ip
  end

  def connect
    self.socket = TCPSocket.new(self.ip,4998)    
  end

  def connected?
    !!self.socket
  end

  def set_learning_mode(state)
    if state
      write("get_IRL\r")
      expect_response("IR Learner Enabled\r" => true)
    else
      write("stop_IRL\r")
      expect_response("IR Learner Disabled\r" => false)
    end
  end

  def listen_for_learning_responses(&block)
    while connected?
      str = ""
      until str[-2..-1] == "\r\n"
        str << read_block(1)
      end
      yield str
    end
  end


  # protected

  def write(values)
    self.socket << values
  end

  def read_from_unblock_to_block
    sleep(0.01) until result = read(1)
    while byte = read(1)
      result << byte
    end
    result
  end

  def read(bytes)
    socket.recv_nonblock(bytes)
  rescue Errno::EAGAIN
    nil
  end

  def read_block(bytes)
    socket.recv(bytes)
  end

  def expect_response(expected_hash)
    response = read_from_unblock_to_block
    if expected_hash.key?(response)
      expected_hash[response]
    else
      raise "Unexpected response: #{response.inspect} (Can handle: #{expected_hash.inspect}"
    end
  end

end
