require 'spec_helper'

describe ScriptoriaCore::Application do
  context "POST /v1/workflow" do
    it "returns a successful response" do
      post '/v1/workflows'

      expect(response.status).to eq 201
    end
  end
end
