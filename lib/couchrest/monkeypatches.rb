# Monkey patch for faster net/http io
if RUBY_VERSION.to_f < 1.9
  require 'timeout'

  class Net::BufferedIO #:nodoc:
    alias :old_rbuf_fill :rbuf_fill
    def rbuf_fill
      if @io.respond_to?(:read_nonblock)
        begin
          @rbuf << @io.read_nonblock(65536)
        rescue Errno::EWOULDBLOCK
          if IO.select([@io], nil, nil, @read_timeout)
            retry
          else
            raise Timeout::Error, "IO timeout"
          end
        end
      else
        timeout(@read_timeout) do
          @rbuf << @io.sysread(65536)
        end
      end
    end
  end
end
