require 'sinatra/base'

module ScriptoriaCore
  class Application < Sinatra::Base
    get '/' do
      "Hello, world!"
    end
  end
end
