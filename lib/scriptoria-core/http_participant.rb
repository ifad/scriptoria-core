require 'ruote'
require 'httpi'

module ScriptoriaCore
  class HttpParticipant < Ruote::StorageParticipant
    def on_workitem
      re_dispatch(in: '60s') unless request_callback
      super
    end

    def on_cancel
      puts "on_cancel: #{workitem.inspect}"
      super
    end

    protected

    def request_callback
      participant = workitem.participant_name
      url         = workitem.fields['callbacks'][participant]

      puts "Making request to `#{url}' for `#{participant}'"

      request = HTTPI::Request.new
      request.url  = url
      request.body = callback_payload.to_json
      begin
        response = HTTPI.post(request)
        if response.code >= 200 && response.code < 300
          puts "Successful response received"
          true
        else
          puts "Error response received"
          false
        end
      rescue Exception => e
        puts "Exception occured: #{e.inspect}"
        false
      end
    end

    def callback_payload
      # Send all the fields except the callback urls, which are used internally
      fields = workitem.fields.dup
      fields.delete('callbacks')

      {
        workflow_id: workitem.fei.wfid,
        workitem_id: workitem.fei.to_storage_id,
        fields: fields
      }
    end
  end
end
