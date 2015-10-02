require 'ruote'
require 'scriptoria-core/http_participant'

module RuoteTestHelpers
  def build_engine
    Ruote::Dashboard.new Ruote::HashStorage.new
  end

  def build_workitem
    Ruote::Workitem.new(
      'fei' => {
        'expid'     => '0',
        'subid'     => 'abc123',
        'wfid'      => 'wfid123',
        'engine_id' => 'engine',
      },
      'fields' => {
        'callbacks' => {
          'alpha' => 'http://localhost:1234/callback/alpha',
          'beta'  => 'http://localhost:1234/callback/beta'
        },
        'params' => {
          'ref' => 'alpha'
        },
        'dispatched_at' => '2015-10-02 15:43:58.045568 UTC',
        'status'        => 'pending'
      },
      'participant_name' => 'alpha'
    )
  end

  def build_participant(engine, workitem)
    ScriptoriaCore::HttpParticipant.new(engine).tap do |participant|
      # Catch the reply and do nothing
      def participant.reply
      end

      # Set the workitem
      participant.send(:workitem=, workitem)
    end
  end

  def stub_engine(engine)
    allow(RuoteKit).to receive(:engine).and_return(engine)
    engine.register do
      catchall ScriptoriaCore::HttpParticipant
    end
  end

  def store_workitem(engine, workitem)
    doc = workitem.to_h

    doc.merge!(
      'type' => 'workitems',
      '_id' => 'wi!' + workitem.fei.to_storage_id,
      'participant_name' => doc['participant_name'],
      'wfid' => doc['fei']['wfid'])

    engine.storage.put(doc)
  end
end

RSpec.configure do |config|
  config.include RuoteTestHelpers
end
