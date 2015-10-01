require 'spec_helper'

describe ScriptoriaCore::Application do
  context "POST /v1/workflow" do
    let(:result) { double('result', to_s: 'wfid1234') }

    before do
      allow(RuoteKit.engine).to receive(:launch).and_return(result)
    end

    it "returns a successful response" do
      post '/v1/workflows', {
        'workflow' => '[ "participant", { "ref" : "alpha" }, [] ]',
        'callbacks' => [
          {
            'participant' => 'aaa',
            'url'         => 'http://localhost:1234/callback/aaa'
          }
        ]
      }

      expect(response.status).to eq 201
      expect(response.body).to   eq '{"workflow_id":"wfid1234"}'
    end

    it "enqueues the workflow in ruote" do
      expect(RuoteKit.engine).to receive(:launch).with('[ "participant", { "ref" : "alpha" }, [] ]', { callbacks: { 'aaa' => 'http://localhost:1234/callback/aaa' }}).and_return(result)

      post '/v1/workflows', {
        'workflow' => '[ "participant", { "ref" : "alpha" }, [] ]',
        'callbacks' => [
          {
            'participant' => 'aaa',
            'url'         => 'http://localhost:1234/callback/aaa'
          }
        ]
      }

      expect(response.status).to eq 201
    end

    context "validations" do
      it "returns an error if the workflow is missing" do
        post '/v1/workflows', {
          'callbacks' => [
            {
              'participant' => 'aaa',
              'url'         => 'http://localhost:1234/callback/aaa'
            }
          ]
        }

        expect(response.status).to eq 400
        expect(response.body).to   eq '{"error":"workflow is missing"}'
      end

      it "returns an error if the workflow is invalid" do
        allow(RuoteKit.engine).to receive(:launch).and_raise(Ruote::Reader::Error.new("cannot read process definition"))

        post '/v1/workflows', {
          'workflow' => 'define woop',
          'callbacks' => [
            {
              'participant' => 'aaa',
              'url'         => 'http://localhost:1234/callback/aaa'
            }
          ]
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
