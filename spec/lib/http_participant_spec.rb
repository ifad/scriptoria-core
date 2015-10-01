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

  def store_workitem(engine, workitem)
    doc = workitem.to_h

    doc.merge!(
      'type' => 'workitems',
      '_id' => 'wi!' + workitem.fei.to_storage_id,
      'participant_name' => doc['participant_name'],
      'wfid' => doc['fei']['wfid'])

    engine.storage.put(doc)
  end

  subject { setup_participant(engine, workitem) }

  before do
    allow(RuoteKit).to receive(:engine).and_return(engine)
    engine.register do
      catchall ScriptoriaCore::HttpParticipant
    end
  end

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

  context "::proceed" do
    before do
      store_workitem(engine, workitem)
      allow(RuoteKit.engine).to receive(:participant).and_return(subject)
    end

    it "raises an error if the workitem can't be found" do
      expect {
        described_class.proceed('wfid123', 'nonexistant')
      }.to raise_error("workitem not found")
    end

    it "raises an error if the workflow id is incorrect" do
      expect {
        described_class.proceed('nonexistant', '0!abc123!wfid123')
      }.to raise_error("workflow mismatch")
    end

    it "merges the fields with the workitem" do
      allow(Ruote::Workitem).to receive(:new).and_return(workitem)
      described_class.proceed('wfid123', '0!abc123!wfid123', { "status" => "error" })
      expect(workitem.fields["status"]).to eq "error"
    end

    it "calls #proceed on the participant" do
      expect(subject).to receive(:proceed).with(workitem)
      described_class.proceed('wfid123', '0!abc123!wfid123')
    end
  end
end
