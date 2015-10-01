require 'grape'
require 'grape_logging'

module ScriptoriaCore
  class Application < Grape::API
    version 'v1', :using => :path
    format :json
    logger ScriptoriaCore.logger

    logger.formatter = GrapeLogging::Formatters::Default.new
    use GrapeLogging::Middleware::RequestLogger, { logger: logger }

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

      post do
        # Convert array of callbacks to a hashmap
        callbacks = params[:callbacks].inject({}) do |hash, callback|
          hash[callback['participant']] = callback['url']
          hash
        end

        wfid = RuoteKit.engine.launch(params[:workflow], { callbacks: callbacks })

        {
          workflow_id: wfid
        }
      end

      route_param :workflow_id do
        resource :workitems do
          route_param :workitem_id do

            params do
              requires :workflow_id, type: String
              requires :workitem_id, type: String
              requires :fields, type: Hash
            end

            post :proceed do
              ScriptoriaCore::HttpParticipant.proceed(
                params[:workflow_id],
                params[:workitem_id],
                params[:fields]
              )
            end

          end
        end
      end
    end
  end
end
