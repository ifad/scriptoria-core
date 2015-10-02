require 'spec_helper'

describe ScriptoriaCore::Workflow do
  context "#validate!" do
    it "validates a JSON workflow" do
      workflow = described_class.new(workflow: '[ "participant", { "ref" : "alpha" }, [] ]', callbacks: { "alpha" => "http://localhost:1234/callbacks/alpha" })
      expect { workflow.validate! }.to_not raise_error
    end

    it "validates a XML workflow" do
      workflow = described_class.new(workflow: '<process-definition><participant ref="alpha" /></process-definition>', callbacks: { "alpha" => "http://localhost:1234/callbacks/alpha" })
      expect { workflow.validate! }.to_not raise_error
    end

    it "catches an invalid workflow" do
      workflow = described_class.new(workflow: 'invalid', callbacks: { "alpha" => "http://localhost:1234/callbacks/alpha" })
      expect { workflow.validate! }.to raise_error(ScriptoriaCore::Workflow::WorkflowInvalidError)
    end
  end

  context "#save!" do
    let(:result) { "wfid1234" }

    before do
      allow(RuoteKit.engine).to receive(:launch).and_return(result)
    end

    subject {
      described_class.new(workflow: '[ "participant", { "ref" : "alpha" }, [] ]', callbacks: { "alpha" => "http://localhost:1234/callbacks/alpha" })
    }

    it "saves the workflow in Ruote" do
      expect(RuoteKit.engine).to receive(:launch).with('[ "participant", { "ref" : "alpha" }, [] ]', { callbacks: { 'alpha' => 'http://localhost:1234/callbacks/alpha' }}).and_return(result)

      subject.save!
    end

    it "assigns the workflow id" do
      subject.save!
      expect(subject.id).to eq 'wfid1234'
    end
  end
end
