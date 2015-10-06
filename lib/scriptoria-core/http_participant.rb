require 'ruote'
require 'httpi'

module ScriptoriaCore
  # A Ruote participant which makes asynchronous HTTP calls to an external
  # application to begin processing the workflow step.
  #
  # Unlike {https://github.com/tosch/ruote-jig ruote-jig} this doesn't expect
  # the external application to reply straight away. The external application
  # makes a callback back to the API when it is ready for the workflow to
  # proceed, this makes it suitable for tasks such as asking for user input.
  class HttpParticipant < Ruote::StorageParticipant

    # Handle the `on_workitem` event (triggered at the start of a participant).
    #
    # Performs the HTTP request to the external application with the status of
    # `active`, to tell the application to start performing work. If an error
    # occurs the workitem is redispatched, so that the request will be retried,
    # in one minute.
    def on_workitem
      ScriptoriaCore.logger.info "On workitem"
      re_dispatch(in: '60s') unless make_callback_request!(true)
      super
    end

    # Handle the `on_cancel` event (triggerd when an error or timeout occurs).
    #
    # Performs the HTTP request to the external application with the status of
    # `active`, to tell the application to stop performing work. If an error
    # occurs no retries are performed.
    def on_cancel
      ScriptoriaCore.logger.info "On cancel"
      make_callback_request!
      super
    end

    # Makes a HTTP request to the external application, called both when a
    # participant starts and when an error or timeout occurs.
    #
    # This expects a 2xx response (the body is ignored), and other response
    # will cause it to be treated as a failure.
    #
    # An exception will be raised if no callback URL is set for the pariticant,
    # see {ScriptoriaCore::Workitem#callback_url} for more details.
    #
    # @param reset_status [boolean] Resets the workitem status. See
    #   {ScriptoriaCore::Workitem#reset_status!} for more details.
    #
    # @raise [MissingCallbackUrl] if no callback URL is set for the
    #   participant.
    #
    # @return [boolean] `true` if the request was successful, `false`
    #   otherwise.
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
