require 'grape'
require 'grape_logging'

module ScriptoriaCore
  # Scriptoria Core API - version 1.
  #
  # See {API_v1.md} and {spec/requests/v1/} for more details.
  class Application < Grape::API
    version 'v1', :using => :path
    format :json
    logger ScriptoriaCore.logger

    logger.formatter = GrapeLogging::Formatters::Default.new
    use GrapeLogging::Middleware::RequestLogger, { logger: logger }

    format :json
    get '/ping' do
      { ping: 'pong' }
    end

    resource :workflows do
      params do
        requires :workflow,  type: String
        optional :callback,  type: String
        optional :callbacks, type: Hash
        optional :fields,    type: Hash
        exactly_one_of :callback, :callbacks
      end

      rescue_from Workflow::WorkflowInvalidError do |e|
        error!('workflow is invalid', 400)
      end

      post do
        workflow = Workflow.create!(
          params[:workflow],
          params[:callback] || params[:callbacks],
          params[:fields]
        )

        {
          id: workflow.id
        }
      end

      route_param :workflow_id do

        params do
          requires :workflow_id, type: String
        end

        rescue_from Workflow::NotFoundError do |e|
          error!('workflow_id not found', 400)
        end

        post :cancel do
          Workflow.cancel!(
            params[:workflow_id]
          )
        end

        resource :workitems do
          route_param :workitem_id do

            params do
              requires :workflow_id, type: String
              requires :workitem_id, type: String
              optional :fields, type: Hash
            end

            rescue_from Workitem::NotFoundError do |e|
              error!('workitem_id not found', 400)
            end

            rescue_from Workitem::WorkflowMismatchError do |e|
              error!('workflow_id is mismatched', 400)
            end

            post :proceed do
              workitem = Workitem.find(
                params[:workflow_id],
                params[:workitem_id]
              )
              workitem.update_fields(params[:fields])
              workitem.proceed!
            end

          end
        end
      end
    end
  end
end
