module Rack
  class Spellcheck
    DICTIONARIES = "doc/en_US,doc/en_US_OpenMedSpel"

    def initialize(app, ignored_fields = nil)
      @app = app
      @ignored_fields ||= ["utf8", "authenticity_token", "commit"]
    end

    def call(env)
      req = Rack::Request.new(env)
      if req.post? || req.put? # create or update
        mispellings = req.params.dup.reject {|key, val| @ignored_fields.include?(key.to_s)}
        mispellings = check_params(mispellings)
        req.session[:mispellings] = mispellings
        puts "Set mispellings in session to: #{mispellings}"
      end

      status, headers, response = @app.call(env)
      [status, headers, response]
    end

    def check_params(params)
      params.each do |(key, val)|
        if val.is_a?(String)
          params[key] = check(val)
        elsif val.is_a?(Hash)
          params[key] = check_params(val.clone)
        else
          raise "Don't know how to handle #{val.class.name}"
        end
      end
    end

    def check(string)
      mispellings = []
      IO.popen("hunspell -l -d #{DICTIONARIES}", "w+") do |f|
        f.puts string
        f.close_write
        while(output = f.gets)
          mispellings << output.strip
        end
      end
      return mispellings
    end

  end
end
