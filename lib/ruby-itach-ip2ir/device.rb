=begin
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

=end

require "socket"

class RubyItachIp2ir::Device
  attr_accessor :ip
  attr_accessor :port
  attr_accessor :socket
  attr_accessor :requests_count

  def initialize(ip, port = 4998)
    self.ip = ip
    self.port = port
    self.requests_count = 0
  end

  def connect(timeout = 5)
    # Uses non-blocking connections to make the timeout handling more efficient.
    # Taken from http://spin.atomicobject.com/2013/09/30/socket-connection-timeout-ruby/

    host = self.ip
    port = self.port

    addr = Socket.getaddrinfo(host, nil)
    sockaddr = Socket.pack_sockaddr_in(port, addr[0][3])

    begin

      self.socket = Socket.new(Socket.const_get(addr[0][0]), Socket::SOCK_STREAM, 0)
      self.socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)


      # Initiate the socket connection in the background. If it doesn't fail
      # immediatelyit will raise an IO::WaitWritable (Errno::EINPROGRESS)
      # indicating the connection is in progress.
      self.socket.connect_nonblock(sockaddr)

    rescue IO::WaitWritable
      # IO.select will block until the socket is writable or the timeout
      # is exceeded - whichever comes first.
      if IO.select(nil, [socket], nil, timeout)
        begin
          # Verify there is now a good connection
          self.socket.connect_nonblock(sockaddr)
        rescue Errno::EISCONN
          # Good news everybody, the socket is connected!

        rescue
          # An unexpected exception was raised - the connection is no good.
          self.socket.close
          raise
        end
      else
        # IO.select returns nil when the socket is not ready before timeout
        # seconds have elapsed
        self.socket.close
        raise "Connection timeout"
      end
    end

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


  # TODO: this will receive string starting with "sendir,...", handle it
  def send_ir_raw(send_ir_string)
    send_ir( *send_ir_string.split(",",7) )
  end

  # TODO: handle correct sending of sendir prefix
  def send_ir(device_id,request_id,freq,repeat,offset,ir_string)
    raise BadDeviceIdFormat unless device_id =~ /\A[0-9:]+\Z/
    request_id = generate_request_id if request_id.nil? or request_id == :auto
    send_ir_string = [device_id,request_id,freq,repeat,offset,ir_string].join(",")

    write("sendir,#{send_ir_string}\r")
    expect_response("completeir,#{device_id},#{request_id}\r" => true)
  end


  def generate_request_id
    self.requests_count = 0 if self.requests_count >= 65535
    self.requests_count += 1
    self.requests_count
  end

  def close
    self.socket.close if connected?
  end

  protected

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
      raise UnexpectedResponse, "#{response.inspect} (Can handle: #{expected_hash.inspect}"
    end
  end

  class UnexpectedResponse < RuntimeError; end
  class BadDeviceIdFormat < RuntimeError; end

end
