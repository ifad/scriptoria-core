require 'grape'

module ScriptoriaCore
  class Application < Grape::API
    version 'v1', :using => :path
    format :json

    resource :workflows do
      post '/' do

      end
    end
  end
end
