module ScriptoriaCore
  # This class abstracts a Ruote workitem.
  class Workitem

    # @return [String] ID of the workitem.
    attr_accessor :id

    # @return [String] ID of the workflow this workitem belongs to.
    attr_accessor :workflow_id

    # @return [Ruote::Workitem] internal Ruote workitem, should not be accessed
    #   directly.
    attr_accessor :_workitem

    # Creates a new instance from a Ruote workitem.
    #
    # @param ruote_workitem [Ruote::Workitem]
    def self.from_ruote_workitem(ruote_workitem)
      workitem_id = ruote_workitem.fei.to_storage_id
      workflow_id = ruote_workitem.fei.wfid

      self.new(
        id:          workitem_id,
        workflow_id: workflow_id,
        _workitem:   ruote_workitem
      )
    end

    # Finds an instance by workflow and workitem IDs.
    #
    # @param workflow_id [String] Workflow ID
    # @param workitem_id [String] Workitem ID
    #
    # @raise [NotFoundError] if the workitem doesn't exist in Ruote.
    # @raise [WorkflowMismatchError] if the workflow ID doesn't match the
    #   workitem.
    def self.find(workflow_id, workitem_id)
      hwi = ScriptoriaCore::Ruote.engine.storage.get('workitems', 'wi!' + workitem_id)
      raise NotFoundError if hwi.nil?

      ruote_workitem = ::Ruote::Workitem.new(hwi)
      raise WorkflowMismatchError if workflow_id != ruote_workitem.wfid

      self.new(
        id:          workitem_id,
        workflow_id: workflow_id,
        _workitem:   ruote_workitem
      )
    end

    def initialize(attributes = {})
      attributes.each do |k, v|
        send("#{k}=", v)
      end
    end

    # @return [String] the active participant name.
    def participant_name
      _workitem.participant_name
    end

    # Returns the callback URL for this participant, based upon the callback
    # URLs passed when the workflow was created.
    #
    # @return [String] callback URL.
    # @raise [MissingCallbackUrl] if no URL is set for the active participant.
    def callback_url
      url = if _workitem.fields['callbacks'].is_a?(String)
              _workitem.fields['callbacks']
            else
              _workitem.fields['callbacks'][participant_name]
            end
      if url.nil?
        raise MissingCallbackUrl
      else
        url
      end
    end

    # Returns the status of the workitem.
    #
    # When an error or timeout occurs one of these fields is set on the
    # workitem, then the `on_error` method is called on a participant. We use
    # this to generate the `status` field which is sent in the callback.
    #
    # @param default_status [symbol] Default status if there is no error status
    #
    # @return [Symbol] Workitem status, one of `:active`, `:timeout` or
    #   `:error`.
    def status(default_status = :active)
      if _workitem.fields.has_key?("__timed_out__")
        :timeout
      elsif _workitem.fields.has_key?("__error__")
        :error
      else
        default_status
      end
    end

    # Returns the callback payload to be sent in callback requests to external
    # applications.
    #
    # @param state [symbol] State of the workitem, `active` or `cancel`.
    #
    # @return [Hash] callback payload.
    def callback_payload(state)
      status = if state == :active
                 :active
               else
                 self.status(state)
               end

      {
        workflow_id: workflow_id,
        workitem_id: id,
        participant: participant_name,
        status:      status,
        fields:      fields,
        proceed_url: proceed_url
      }
    end

    # Reader for public fields in the workitem.
    def fields
      fields = _workitem.fields.dup
      fields.delete("callbacks")
      fields.delete("dispatched_at")
      fields
    end

    # Merges `fields` with the existing fields on the workitem, with those
    # passed in taking precidence.
    #
    # @param fields [Hash] new fields.
    def update_fields(fields)
      return if fields.nil?

      fields.each do |k, v|
        _workitem.fields[k] = v
      end
    end

    # Calls the proceed action on the workitem.
    def proceed!
      participant.proceed(_workitem)
    end

    # Uses https://github.com/jmettraux/ruote/commit/33a407f to update a
    # workitem. Only intended for debugging, use with caution!
    def save!
      ScriptoriaCore::Ruote.engine.storage_participant.do_update(_workitem)
    end

    protected

    # Returns the instance of HttpParticipant that is registered with Ruote.
    def participant
      ScriptoriaCore::Ruote.engine.participant(participant_name)
    end

    # To be called by the client application to prcoeed this workitem
    def proceed_url
      "#{ENV['BASE_URL']}/v1/workflows/#{workflow_id}/workitems/#{id}/proceed"
    end

    class NotFoundError         < StandardError; end
    class WorkflowMismatchError < StandardError; end
    class MissingCallbackUrl    < StandardError; end
  end
end
