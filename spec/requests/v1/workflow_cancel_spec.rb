require 'spec_helper'

describe ScriptoriaCore::Application do
  context "POST /v1/workflow/:workflow_id/cancel" do
    let(:workflow) { double('workflow', id: 'wfid1234') }

    before do
      allow(ScriptoriaCore::Workflow).to receive(:cancel!).and_return(true)
    end

    it "returns a successful response" do
      post '/v1/workflows/1234/cancel'
      expect(response.status).to eq 201
    end

    it "initiates cancellation" do
      expect(ScriptoriaCore::Workflow).to receive(:cancel!).with('1234')

      post '/v1/workflows/1234/cancel'
      expect(response.status).to eq 201
    end

    context "validations" do
      it "returns an error if the workflow does not exist" do
        allow(ScriptoriaCore::Workflow).to receive(:cancel!).and_raise(ScriptoriaCore::Workflow::NotFoundError)

        post '/v1/workflows/1234/cancel'

        expect(response.status).to eq 404
        expect(response.body).to   eq '{"error":"workflow_id not found"}'
      end
    end
  end
end
