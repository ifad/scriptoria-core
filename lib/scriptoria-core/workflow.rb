require 'ruote'

module ScriptoriaCore
  class Workflow
    attr_accessor :workflow, :callbacks, :id

    def self.create!(workflow, callbacks)
      new(workflow: workflow, callbacks: callbacks).save!
    end

    def initialize(attributes = {})
      attributes.each do |k, v|
        send("#{k}=", v)
      end
    end

    def validate!
      begin
        Ruote::Reader.read(workflow)
      rescue Exception => e
        raise WorkflowInvalidError
      end
    end

    def save!
      validate!
      self.id = RuoteKit.engine.launch(workflow, { callbacks: callbacks })
      self
    end

    class WorkflowInvalidError < StandardError; end
  end
end
