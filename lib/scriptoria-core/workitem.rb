module ScriptoriaCore
  class Workitem
    attr_accessor :id, :workflow_id, :_workitem

    def self.from_ruote_workitem(ruote_workitem)
      workitem_id = ruote_workitem.fei.to_storage_id
      workflow_id = ruote_workitem.fei.wfid

      self.new(
        id:          workitem_id,
        workflow_id: workflow_id,
        _workitem:   ruote_workitem
      )
    end

    def self.find(workflow_id, workitem_id)
      hwi = RuoteKit.engine.storage.get('workitems', 'wi!' + workitem_id)
      raise NotFoundError if hwi.nil?

      ruote_workitem = Ruote::Workitem.new(hwi)
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

    def participant_name
      _workitem.participant_name
    end

    def callback_url
      url = _workitem.fields['callbacks'][participant_name]
      if url.nil?
        raise MissingCallbackUrl
      else
        url
      end
    end

    def callback_payload
      {
        workflow_id: workflow_id,
        workitem_id: id,
        participant: participant_name,
        fields:      fields,
        proceed_url: proceed_url
      }
    end

    def fields
      fields = _workitem.fields.dup
      fields.delete("callbacks")
      fields.delete("dispatched_at")
      fields
    end

    def update_fields(fields)
      fields.each do |k, v|
        _workitem.fields[k] = v
      end
    end

    def proceed!
      participant.proceed(_workitem)
    end

    protected

    # this returns the instance of this class that is registered with Ruote
    def participant
      RuoteKit.engine.participant(participant_name)
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
