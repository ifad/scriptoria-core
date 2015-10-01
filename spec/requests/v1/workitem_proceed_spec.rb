require 'spec_helper'

describe ScriptoriaCore::Application do
  before do
    allow(ScriptoriaCore::HttpParticipant).to receive(:proceed).and_return(true)
  end

  context "POST /v1/workflow/:workflow_id/workitems/:workitem_id/proceed" do
    it "returns a successful response" do
      post '/v1/workflows/1234/workitems/5678/proceed', {
        "fields" => {
          "status" => "successful"
        }
      }

      expect(response.status).to eq 201
    end

    it "calls proceed on the participant" do
      expect(ScriptoriaCore::HttpParticipant).to receive(:proceed).with('1234', '5678', { "status" => "successful" }).and_return(true)

      post '/v1/workflows/1234/workitems/5678/proceed', {
        "fields" => {
          "status" => "successful"
        }
      }

      expect(response.status).to eq 201
    end

    context "validations" do
      it "returns an error if the fields are missing" do
        post '/v1/workflows/1234/workitems/5678/proceed', {}

        expect(response.status).to eq 400
        expect(response.body).to   eq '{"error":"fields is missing"}'
      end
    end
  end
end
