require "thin"

module TwoCho
  class FileServer
    attr_reader :port, :thin_server

    def initialize(port)
      @port = port

      Thin::Logging.silent = true

      @thin_server = Thin::Server.new "127.0.0.1", port
      thin_server.app = Rack::Builder.new do
        map "/" do
          run Rack::Directory.new("images")
        end
      end
    end

    def run
      Thread.new { thin_server.start }
    end

    def stop
      thin_server.stop
    end
  end
end
