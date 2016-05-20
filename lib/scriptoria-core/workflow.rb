require 'ruote/reader'

module ScriptoriaCore
  # This class abstracts a Ruote workflow.
  class Workflow

    # @return [String] ID of the workflow.
    attr_accessor :id

    # @return [String] Ruote process definition.
    attr_accessor :workflow

    # @return [Hash/String] Callback URLs.
    attr_accessor :callbacks

    # @return [Hash] Default workitem payload.
    attr_accessor :fields

    # Creates and launches a workflow in Ruote.
    #
    # @param workflow [String] A process definition in any format Ruote can
    #   understand (XML, JSON, Radial).
    # @param callbacks [Hash] Callback URLs.
    # @param fields    [Hash] Default workitem payload.
    # @raise [WorkflowInvalidError] if the process definition is invalid.
    def self.create!(workflow, callbacks, fields = {})
      new(workflow: workflow, callbacks: callbacks, fields: fields).save!
    end

    # Initiates cancellation of a workflow.
    #
    # Will call `on_cancel` on all active participants, and remove schedules
    # and erros.
    #
    # @param workflow_id [String] Workflow ID
    #
    # @raise [NotFoundError] if the workflow doesn't exist in Ruote.
    def self.cancel!(workflow_id)
      process = ScriptoriaCore::Ruote.engine.process(workflow_id)
      raise NotFoundError if process.nil?

      # Initiate cancellation of the process
      ScriptoriaCore::Ruote.engine.cancel_process(workflow_id)

      # Delete errors and scheduled items. This isn't really the right way to
      # clean up as errors or schedules could be added after this, while the
      # process is being cancelled, due to race conditions.
      %w{ errors schedules }.each do |type|
        ScriptoriaCore::Ruote.storage.get_many(type, workflow_id).each do |doc|
          ScriptoriaCore::Ruote.storage.delete(doc)
        end
      end
    end

    def initialize(attributes = {})
      attributes.each do |k, v|
        send("#{k}=", v)
      end
    end

    # Validates the Ruote process definition.
    #
    # @raise [WorkflowInvalidError] if the process definition is invalid.
    def validate!
      begin
        ::Ruote::Reader.read(workflow)
      rescue Exception => e
        raise WorkflowInvalidError
      end
    end

    # Validates and launches the workflow in Ruote.
    #
    # @raise [WorkflowInvalidError] if the process definition is invalid.
    def save!
      validate!
      self.id = ScriptoriaCore::Ruote.engine.launch(workflow, launch_fields)
      ScriptoriaCore.logger.info "Launched workflow #{self.id} with payload #{launch_fields.to_json}"
      self
    end

    class WorkflowInvalidError < StandardError; end
    class NotFoundError        < StandardError; end

    protected

    def launch_fields
      (fields || {}).merge({ callbacks: callbacks })
    end
  end
end
