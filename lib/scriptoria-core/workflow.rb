require 'ruote'

module ScriptoriaCore
  # This class abstracts a Ruote workflow.
  class Workflow

    # @return [String] ID of the workflow.
    attr_accessor :id

    # @return [String] Ruote process definition.
    attr_accessor :workflow

    # @return [Hash] Callback URLs.
    attr_accessor :callbacks

    # Creates and launches a workflow in Ruote.
    #
    # @param workflow [String] A process definition in any format Ruote can
    #   understand (XML, JSON, Radial).
    # @param callbacks [Hash] Callback URLs.
    # @raise [WorkflowInvalidError] if the process definition is invalid.
    def self.create!(workflow, callbacks)
      new(workflow: workflow, callbacks: callbacks).save!
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
        Ruote::Reader.read(workflow)
      rescue Exception => e
        raise WorkflowInvalidError
      end
    end

    # Validates and launches the workflow in Ruote.
    #
    # @raise [WorkflowInvalidError] if the process definition is invalid.
    def save!
      validate!
      self.id = RuoteKit.engine.launch(workflow, { callbacks: callbacks })
      self
    end

    class WorkflowInvalidError < StandardError; end
  end
end
