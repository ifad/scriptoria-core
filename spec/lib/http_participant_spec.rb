require 'spec_helper'
require 'scriptoria-core/http_participant'

describe ScriptoriaCore::HttpParticipant do
  let(:engine)   { build_engine }
  let(:workitem) { build_workitem }

  subject { build_participant(engine, workitem) }

  before do
    stub_engine(engine)
    allow(RuoteKit).to receive(:engine).and_return(engine)
  end

  context "#on_workitem" do
    before do
      ENV['BASE_URL'] = "http://example.com"
    end

    it "makes a POST request to the target URL" do
      stub_request(:post, "http://localhost:1234/callback/alpha").
        to_return(:status => 200)

      subject.on_workitem

      expect(WebMock).to have_requested(:post, "http://localhost:1234/callback/alpha")
    end

    it "includes the workitem id an params in the request" do
      stub_request(:post, "http://localhost:1234/callback/alpha").
        with(body: '{"workflow_id":"wfid123","workitem_id":"0!abc123!wfid123","participant":"alpha","status":"active","fields":{"params":{"ref":"alpha"},"status":"pending"},"proceed_url":"http://example.com/v1/workflows/wfid123/workitems/0!abc123!wfid123/proceed"}').
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

    it "resets the status of a retried workitem" do
      workitem.fields["__timed_out__"] = {}

      stub_request(:post, "http://localhost:1234/callback/alpha").
        with(body: '{"workflow_id":"wfid123","workitem_id":"0!abc123!wfid123","participant":"alpha","status":"active","fields":{"params":{"ref":"alpha"},"status":"pending"},"proceed_url":"http://example.com/v1/workflows/wfid123/workitems/0!abc123!wfid123/proceed"}').
        to_return(:status => 200)

      subject.on_workitem
    end
  end

  context "#on_cancel" do
    before do
      ENV['BASE_URL'] = "http://example.com"
      workitem.fields['__timed_out__'] = {}
    end

    it "makes a POST request to the target URL" do
      stub_request(:post, "http://localhost:1234/callback/alpha").
        to_return(:status => 200)

      subject.on_cancel

      expect(WebMock).to have_requested(:post, "http://localhost:1234/callback/alpha")
    end

    it "includes the workitem id an params in the request" do
      stub_request(:post, "http://localhost:1234/callback/alpha").
        with(body: '{"workflow_id":"wfid123","workitem_id":"0!abc123!wfid123","participant":"alpha","status":"timeout","fields":{"params":{"ref":"alpha"},"status":"pending"},"proceed_url":"http://example.com/v1/workflows/wfid123/workitems/0!abc123!wfid123/proceed"}').
        to_return(:status => 200)

      subject.on_cancel
    end
  end
end
