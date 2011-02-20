module Rack
  class Spellcheck
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, response = @app.call(env)
      puts "Inside Spellcheck"
      [status, headers, response]
    end
  end
end
