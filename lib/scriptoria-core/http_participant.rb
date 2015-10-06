require 'ruote'
require 'httpi'

module ScriptoriaCore
  class HttpParticipant < Ruote::StorageParticipant
    def on_workitem
      ScriptoriaCore.logger.info "On workitem"
      re_dispatch(in: '60s') unless make_callback_request!(true)
      super
    end

    def on_cancel
      ScriptoriaCore.logger.info "On cancel"
      make_callback_request!
      ScriptoriaCore.logger.info workitem.inspect
      super
    end

    def make_callback_request!(reset_status = false)
      sc_workitem = ScriptoriaCore::Workitem.from_ruote_workitem(workitem)
      sc_workitem.reset_status! if reset_status

      ScriptoriaCore.logger.info "Making request to `#{sc_workitem.callback_url}' for `#{sc_workitem.participant_name}'"

      request = HTTPI::Request.new
      request.url     = sc_workitem.callback_url
      request.body    = sc_workitem.callback_payload.to_json
      request.headers = {
        "Content-Type" => "application/json"
      }
      begin
        response = HTTPI.post(request)
        if response.code >= 200 && response.code < 300
          ScriptoriaCore.logger.info "Successful response received"
          true
        else
          ScriptoriaCore.logger.info "Error response received"
          false
        end
      rescue Exception => e
        ScriptoriaCore.logger.info "Exception occured: #{e.inspect}"
        false
      end
    end
  end
end
