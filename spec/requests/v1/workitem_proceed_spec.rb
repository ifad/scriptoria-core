require 'spec_helper'

describe ScriptoriaCore::Application do
  let(:workitem) { double('workitem', update_fields: true, proceed!: true) }

  before do
    allow(ScriptoriaCore::Workitem).to receive(:find).with('1234', '5678').and_return(workitem)
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

    it "updates the fields on the workitem" do
      expect(workitem).to receive(:update_fields).with({ "status" => "successful" }).and_return(true)

      post '/v1/workflows/1234/workitems/5678/proceed', {
        "fields" => {
          "status" => "successful"
        }
      }

      expect(response.status).to eq 201
    end

    it "calls proceed on the workitem" do
      expect(workitem).to receive(:proceed!).and_return(true)

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

      it "returns an error if the workitem can't be found" do
        allow(ScriptoriaCore::Workitem).to receive(:find).and_raise(ScriptoriaCore::Workitem::NotFoundError)
        post '/v1/workflows/1234/workitems/5678/proceed', {
          "fields" => {
            "status" => "successful"
          }
        }

        expect(response.status).to eq 400
        expect(response.body).to   eq '{"error":"workitem_id not found"}'
      end

      it "returns an error if the workflow id is mismatched" do
        allow(ScriptoriaCore::Workitem).to receive(:find).and_raise(ScriptoriaCore::Workitem::WorkflowMismatchError)
        post '/v1/workflows/1234/workitems/5678/proceed', {
          "fields" => {
            "status" => "successful"
          }
        }

        expect(response.status).to eq 400
        expect(response.body).to   eq '{"error":"workflow_id is mismatched"}'
      end
    end
  end
end
