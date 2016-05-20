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
  class HttpParticipant < ::Ruote::StorageParticipant

    # The maximum number of retries to attempt. After this instead of retrying,
    # the `RetriesExceededError` will be raised.
    MAX_RETRIES = 10

    # Handle the `on_workitem` event (triggered at the start of a participant).
    #
    # Performs the HTTP request to the external application with the status of
    # `active`, to tell the application to start performing work. If an error
    # occurs during the HTTP request, the workitem is redispatched and the
    # request will be retried (see `#attempt_retry`).
    def on_workitem
      ScriptoriaCore.logger.info "On workitem"
      attempt_retry unless make_callback_request!(:active)
      super
    rescue Exception => e
      ScriptoriaCore.logger.error "Got error #{e.inspect} for #{workitem.inspect}"
      raise e
    end

    # Handle the `on_cancel` event (triggerd when an error or timeout occurs).
    #
    # Performs the HTTP request to the external application with the status of
    # `cancel`, to tell the application to stop performing work. If an error
    # occurs no retries are performed.
    def on_cancel
      ScriptoriaCore.logger.info "On cancel"
      make_callback_request!(:cancel)
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
    # The state of the workitem depends on the participant callback, if it is
    # received in the `on_workitem` callback the state should be `active`, if
    # received in the `on_cancel` callback the state should be `cancel`.
    #
    # @param state [symbol] State of the workitem, `active` or `cancel`.
    #
    # @raise [MissingCallbackUrl] if no callback URL is set for the
    #   participant.
    #
    # @return [boolean] `true` if the request was successful, `false`
    #   otherwise.
    def make_callback_request!(state)
      sc_workitem = ScriptoriaCore::Workitem.from_ruote_workitem(workitem)
      payload     = sc_workitem.callback_payload(state).to_json

      ScriptoriaCore.logger.info "Making request to `#{sc_workitem.callback_url}' for `#{sc_workitem.participant_name}'"
      ScriptoriaCore.logger.info "Payload: #{payload}"

      request = HTTPI::Request.new
      request.url     = sc_workitem.callback_url
      request.body    = payload
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

    # Raised when the number of retries has been exceeded. If you have an
    # `on_error` handler in the workflow it will be called, otherwise the
    # workflow will be put into an error state.
    class RetriesExceededError < StandardError; end

    protected

    # Attempt to redispatch the workflow, with expontential backoff between
    # retries. After `MAX_RETRIES` we give up and raise `RetriesExceededError`.
    def attempt_retry
      retry_count = workitem.re_dispatch_count

      if retry_count <= MAX_RETRIES
        delay = seconds_to_delay(retry_count)

        ScriptoriaCore.logger.info "Retry in #{delay} seconds"
        re_dispatch(in: "#{delay}s")
      else
        raise RetriesExceededError
      end
    end

    # Returns the number of seconds to delay until the next retry.
    #
    # Retry 0  - T0 +     30 (30s)
    # Retry 1  - T0 +     61 (1m)
    # Retry 2  - T0 +    123 (2m)
    # Retry 3  - T0 +    396 (6m)
    # Retry 4  - T0 +   1450 (24m)
    # Retry 5  - T0 +   4605 (1h)
    # Retry 6  - T0 +  12411 (3h)
    # Retry 7  - T0 +  29248 (8h)
    # Retry 8  - T0 +  62046 (17h)
    # Retry 9  - T0 + 121125 (1d)
    # Retry 10 - T0 + 221155 (2d)
    def seconds_to_delay(count)
      (count ** 5) + 30
    end
  end
end
