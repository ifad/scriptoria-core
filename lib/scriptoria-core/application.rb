require 'grape'

module ScriptoriaCore
  class Application < Grape::API
    version 'v1', :using => :path
    format :json

    resource :workflows do
      params do
        # This is actually JSON, but we want to decode it ourselves
        requires :workflow, type: String

        requires :callbacks, type: Array do
          requires :participant, type: String
          requires :url, type: String
        end
      end

      rescue_from Ruote::Reader::Error do |e|
        error!('workflow is invalid', 400)
      end

      post '/' do
        # TODO store callbacks somewhere (inside the workflow?)
        wfid = RuoteKit.engine.launch(params[:workflow])
      end
    end
  end
end
