require 'spec_helper'
require 'scriptoria-core/http_participant'

describe ScriptoriaCore::HttpParticipant do
  let(:engine)   { Ruote::Dashboard.new(Ruote::HashStorage.new()) }
  let(:workitem) { Ruote::Workitem.new(
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
      'status' => 'active'
    },
    'participant_name' => 'alpha'
  )}

  def setup_participant(engine, workitem)
    ScriptoriaCore::HttpParticipant.new(engine).tap do |participant|
      # Catch the reply and do nothing
      def participant.reply
      end

      # Set the workitem
      participant.send(:workitem=, workitem)
    end
  end

  subject { setup_participant(engine, workitem) }

  context "#on_workitem" do
    it "makes a POST request to the target URL" do
      stub_request(:post, "http://localhost:1234/callback/alpha").
        to_return(:status => 200)

      subject.on_workitem

      expect(WebMock).to have_requested(:post, "http://localhost:1234/callback/alpha")
    end

    it "includes the workitem id an params in the request" do
      stub_request(:post, "http://localhost:1234/callback/alpha").
        with(body: '{"workflow_id":"wfid123","workitem_id":"0!abc123!wfid123","fields":{"status":"active"}}').
        to_return(:status => 200)

      subject.on_workitem

    end

    it "requeues the workitem when a non 200 request is received" do
      stub_request(:post, "http://localhost:1234/callback/alpha").
        to_return(:status => 500)

      expect(subject).to receive(:re_dispatch).with(in: '60s')

      subject.on_workitem
    end

    it "requeues the workitem when a connection error occurs" do
      stub_request(:post, "http://localhost:1234/callback/alpha").
        to_timeout

      expect(subject).to receive(:re_dispatch).with(in: '60s')

      subject.on_workitem
    end
  end
end
