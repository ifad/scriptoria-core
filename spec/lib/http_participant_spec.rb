require 'spec_helper'
require 'scriptoria-core/http_participant'

describe ScriptoriaCore::HttpParticipant do
  let(:engine)   { build_engine }
  let(:workitem) { build_workitem }

  subject { build_participant(engine, workitem) }

  before do
    stub_engine(engine)
    allow(ScriptoriaCore::Ruote).to receive(:engine).and_return(engine)
  end

  context "#on_workitem" do
    before do
      ENV['BASE_URL'] = "http://example.com"
    end

    it "makes a POST request to the target URL" do
      stub_request(:post, "http://localhost:1234/callback/alpha").
        to_return(status: 200)

      subject.on_workitem

      expect(WebMock).to have_requested(:post, "http://localhost:1234/callback/alpha")
    end

    it "includes the workitem id an params in the request" do
      stub_request(:post, "http://localhost:1234/callback/alpha").
        with(body: '{"workflow_id":"wfid123","workitem_id":"0!abc123!wfid123","participant":"alpha","status":"active","fields":{"params":{"ref":"alpha"},"status":"pending"},"proceed_url":"http://example.com/v1/workflows/wfid123/workitems/0!abc123!wfid123/proceed"}').
        to_return(status: 200)

      subject.on_workitem
    end

    it "makes a POST request to the catch-all URL if present" do
      workitem.h.fields["callbacks"] = "http://localhost:1234/callbacks"

      stub_request(:post, "http://localhost:1234/callbacks").
        to_return(status: 200)

      subject.on_workitem

      expect(WebMock).to have_requested(:post, "http://localhost:1234/callbacks")
    end

    context "failed request" do
      it "redispatches the workitem when a non 200 request is received" do
        stub_request(:post, "http://localhost:1234/callback/alpha").
          to_return(status: 500)

        expect(subject).to receive(:re_dispatch).with(in: '30s')

        subject.on_workitem
      end

      it "redispatches the workitem when a connection error occurs" do
        stub_request(:post, "http://localhost:1234/callback/alpha").
          to_timeout

        expect(subject).to receive(:re_dispatch).with(in: '30s')

        subject.on_workitem
      end
    end

    context "failed request retries" do
      before do
        stub_request(:post, "http://localhost:1234/callback/alpha").
          to_return(status: 500)
      end

      it "perform a retries with exponetial backoff" do
        workitem.h.re_dispatch_count = 0
        expect(subject).to receive(:re_dispatch).with(in: '30s')
        subject.on_workitem

        workitem.h.re_dispatch_count = 1
        expect(subject).to receive(:re_dispatch).with(in: '31s')
        subject.on_workitem

        workitem.h.re_dispatch_count = 2
        expect(subject).to receive(:re_dispatch).with(in: '62s')
        subject.on_workitem
      end

      it "raises RetriesExceededError after 11 retries" do
        workitem.h.re_dispatch_count = 10
        expect(subject).to receive(:re_dispatch).with(in: '100030s')
        subject.on_workitem

        workitem.h.re_dispatch_count = 11
        expect {
          subject.on_workitem
        }.to raise_error(ScriptoriaCore::HttpParticipant::RetriesExceededError)
      end
    end

    context "missing callback url" do
      it "raises an error" do
        workitem.h.participant_name = 'nothing'
        expect {
          subject.on_workitem
        }.to raise_error(ScriptoriaCore::Workitem::MissingCallbackUrl)
      end
    end
  end

  context "#on_cancel" do
    before do
      ENV['BASE_URL'] = "http://example.com"
    end

    it "makes a POST request to the target URL" do
      stub_request(:post, "http://localhost:1234/callback/alpha").
        to_return(status: 200)

      subject.on_cancel

      expect(WebMock).to have_requested(:post, "http://localhost:1234/callback/alpha")
    end

    it "includes the workitem id an params in the request" do
      stub_request(:post, "http://localhost:1234/callback/alpha").
        with(body: '{"workflow_id":"wfid123","workitem_id":"0!abc123!wfid123","participant":"alpha","status":"cancel","fields":{"params":{"ref":"alpha"},"status":"pending"},"proceed_url":"http://example.com/v1/workflows/wfid123/workitems/0!abc123!wfid123/proceed"}').
        to_return(status: 200)

      subject.on_cancel
    end

    it "includes the status 'cancel' if cancelled" do
      stub_request(:post, "http://localhost:1234/callback/alpha").
        with(body: '{"workflow_id":"wfid123","workitem_id":"0!abc123!wfid123","participant":"alpha","status":"cancel","fields":{"params":{"ref":"alpha"},"status":"pending"},"proceed_url":"http://example.com/v1/workflows/wfid123/workitems/0!abc123!wfid123/proceed"}').
        to_return(status: 200)

      subject.on_cancel
    end

    it "includes the status 'timeout' if cancelled due to a timeout" do
      workitem.fields['__timed_out__'] = {}

      stub_request(:post, "http://localhost:1234/callback/alpha").
        with(body: '{"workflow_id":"wfid123","workitem_id":"0!abc123!wfid123","participant":"alpha","status":"timeout","fields":{"params":{"ref":"alpha"},"status":"pending"},"proceed_url":"http://example.com/v1/workflows/wfid123/workitems/0!abc123!wfid123/proceed"}').
        to_return(status: 200)

      subject.on_cancel
    end
  end
end
