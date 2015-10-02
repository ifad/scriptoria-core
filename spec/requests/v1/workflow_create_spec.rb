require 'spec_helper'

describe ScriptoriaCore::Application do
  context "POST /v1/workflow" do
    let(:workflow) { double('workflow', id: 'wfid1234') }

    before do
      allow(ScriptoriaCore::Workflow).to receive(:create!).and_return(workflow)
    end

    it "returns a successful response" do
      post '/v1/workflows', {
        'workflow' => '[ "participant", { "ref" : "alpha" }, [] ]',
        'callbacks' => {
          'alpha' => 'http://localhost:1234/callback/alpha'
        }
      }

      expect(response.status).to eq 201
      expect(response.body).to   eq '{"id":"wfid1234"}'
    end

    it "creates a workflow" do
      expect(ScriptoriaCore::Workflow).to receive(:create!).with('[ "participant", { "ref" : "alpha" }, [] ]', { 'alpha' => 'http://localhost:1234/callback/alpha' }).and_return(workflow)

      post '/v1/workflows', {
        'workflow' => '[ "participant", { "ref" : "alpha" }, [] ]',
        'callbacks' => {
          'alpha' => 'http://localhost:1234/callback/alpha'
        }
      }

      expect(response.status).to eq 201
    end

    context "validations" do
      it "returns an error if the workflow is missing" do
        post '/v1/workflows', {
          'callbacks' => {
            'alpha' => 'http://localhost:1234/callback/alpha'
          }
        }

        expect(response.status).to eq 400
        expect(response.body).to   eq '{"error":"workflow is missing"}'
      end

      it "returns an error if the workflow is invalid" do
        allow(ScriptoriaCore::Workflow).to receive(:create!).and_raise(ScriptoriaCore::Workflow::WorkflowInvalidError)

        post '/v1/workflows', {
          'workflow' => 'define woop',
          'callbacks' => {
            'alpha' => 'http://localhost:1234/callback/alpha'
          }
        }

        expect(response.status).to eq 400
        expect(response.body).to   eq '{"error":"workflow is invalid"}'
      end

      it "returns an error if the callbacks are missing" do
        post '/v1/workflows', {
          'workflow' => '[ "participant", { "ref" : "alpha" }, [] ]',
        }

        expect(response.status).to eq 400
        expect(response.body).to   eq '{"error":"callbacks is missing"}'
      end
    end
  end
end
