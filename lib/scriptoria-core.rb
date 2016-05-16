require 'scriptoria-core/version'

module ScriptoriaCore
  autoload :Application,     'scriptoria-core/application'
  autoload :HttpParticipant, 'scriptoria-core/http_participant'
  autoload :Workflow,        'scriptoria-core/workflow'
  autoload :Workitem,        'scriptoria-core/workitem'
  autoload :Ruote,           'scriptoria-core/ruote'

  def self.logger=(logger)
    @@logger = logger
  end

  def self.logger
    @@logger ||= Logger.new(STDOUT)
  end
end
