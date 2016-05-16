require 'spec_helper'

describe ScriptoriaCore::Workflow do
  let(:engine) { double('ruote engine') }

  before do
    allow(ScriptoriaCore::Ruote).to receive(:engine).and_return(engine)
  end

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
      allow(engine).to receive(:launch).and_return(result)
    end

    context "without fields" do
      subject {
        described_class.new(
          workflow:  '[ "participant", { "ref" : "alpha" }, [] ]',
          callbacks: { "alpha" => "http://localhost:1234/callbacks/alpha" }
        )
      }

      it "saves the workflow in Ruote" do
        expect(ScriptoriaCore::Ruote.engine).to receive(:launch).with('[ "participant", { "ref" : "alpha" }, [] ]', { callbacks: { 'alpha' => 'http://localhost:1234/callbacks/alpha' }}).and_return(result)

        subject.save!
      end

      it "assigns the workflow id" do
        subject.save!
        expect(subject.id).to eq 'wfid1234'
      end
    end

    context "with fields" do
      subject {
        described_class.new(
          workflow:  '[ "participant", { "ref" : "alpha" }, [] ]',
          callbacks: { "alpha" => "http://localhost:1234/callbacks/alpha" },
          fields:    { 'assignee' => 'j.smith' }
        )
      }

      it "saves the workflow in Ruote" do
        expect(ScriptoriaCore::Ruote.engine).to receive(:launch).with('[ "participant", { "ref" : "alpha" }, [] ]', { 'assignee' => 'j.smith', callbacks: { 'alpha' => 'http://localhost:1234/callbacks/alpha' }}).and_return(result)

        subject.save!
      end

      it "assigns the workflow id" do
        subject.save!
        expect(subject.id).to eq 'wfid1234'
      end
    end
  end
end
