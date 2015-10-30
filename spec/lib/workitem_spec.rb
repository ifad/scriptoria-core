require 'spec_helper'

describe ScriptoriaCore::Workitem do
  let(:engine)         { build_engine }
  let(:ruote_workitem) { build_workitem }
  let(:participant)    { build_participant(engine, ruote_workitem) }

  before do
    stub_engine(engine)
    store_workitem(engine, ruote_workitem)
  end

  subject {
    described_class.from_ruote_workitem(ruote_workitem)
  }

  context "::from_ruote_workitem" do
    it "creates in instance of the class from a ruote workitem" do
      workitem = described_class.from_ruote_workitem(ruote_workitem)

      expect(workitem).to be_kind_of described_class
      expect(workitem.id).to          eq '0!abc123!wfid123'
      expect(workitem.workflow_id).to eq 'wfid123'
      expect(workitem._workitem).to   eq ruote_workitem
    end
  end

  context "::find" do
    it "raises an error if the workitem can't be found" do
      expect {
        described_class.find('wfid123', 'nonexistant')
      }.to raise_error(ScriptoriaCore::Workitem::NotFoundError)
    end

    it "raises an error if the workflow id is incorrect" do
      expect {
        described_class.find('nonexistant', '0!abc123!wfid123')
      }.to raise_error(ScriptoriaCore::Workitem::WorkflowMismatchError)
    end

    it "returns an instance of the class" do
      workitem = described_class.find('wfid123', '0!abc123!wfid123')

      expect(workitem).to be_kind_of described_class
      expect(workitem.id).to          eq '0!abc123!wfid123'
      expect(workitem.workflow_id).to eq 'wfid123'
      expect(workitem._workitem).to   eq ruote_workitem
    end
  end

  context "#participant_name" do
    it "returns the current participant name" do
      expect(subject.participant_name).to eq 'alpha'
    end
  end

  context "#callback_url" do
    it "returns the url for the callback" do
      expect(subject.callback_url).to eq "http://localhost:1234/callback/alpha"
    end

    it "raises an error if the callback url is missing" do
      allow(subject).to receive(:participant_name).and_return('other')
      expect { subject.callback_url }.to raise_error(ScriptoriaCore::Workitem::MissingCallbackUrl)
    end

    it "returns the url for a catch-all callback" do
      ruote_workitem.h.fields["callbacks"] = "http://localhost:1234/callbacks"
      expect(subject.callback_url).to eq "http://localhost:1234/callbacks"
    end
  end

  context "#callback_payload" do
    before do
      ENV['BASE_URL'] = "http://example.com"
    end

    it "returns the callback payload" do
      expect(subject.callback_payload(:active)).to eq({
        workflow_id: 'wfid123',
        workitem_id: '0!abc123!wfid123',
        participant: 'alpha',
        status:      :active,
        fields: {
          "params" => { "ref" => "alpha" },
          "status" => "pending"
        },
        proceed_url: "http://example.com/v1/workflows/wfid123/workitems/0!abc123!wfid123/proceed"
      })
    end

    it "returns the status 'active' when active" do
      expect(subject.callback_payload(:active)[:status]).to eq :active

      ruote_workitem.fields["__timed_out__"] = {}
      expect(subject.callback_payload(:active)[:status]).to eq :active
    end

    it "returns the status 'cancel' when cancelled" do
      expect(subject.callback_payload(:cancel)[:status]).to eq :cancel
    end

    it "returns the status 'timeout' when timed out" do
      ruote_workitem.fields["__timed_out__"] = {}
      expect(subject.callback_payload(:cancel)[:status]).to eq :timeout
    end

    it "returns the status 'error' when an error occured" do
      ruote_workitem.fields["__error__"] = {}
      expect(subject.callback_payload(:cancel)[:status]).to eq :error
    end
  end

  context "#fields" do
    it "returns the public fields for the workitem" do
      expect(subject.fields).to eq({
        "params" => { "ref" => "alpha" },
        "status" => "pending"
      })
    end
  end

  context "#status" do
    it "returns :active if the workitem is active" do
      expect(subject.status). to eq :active
    end

    it "returns :active if the workitem is cancelled" do
      expect(subject.status(:cancel)). to eq :cancel
    end

    it "returns :timeout if the workitem has timed out" do
      ruote_workitem.fields["__timed_out__"] = {}
      expect(subject.status). to eq :timeout
    end

    it "returns :error if the workitem has an error" do
      ruote_workitem.fields["__error__"] = {}
      expect(subject.status). to eq :error
    end
  end

  context "#update_fields" do
    it "updates the fields on the workitem" do
      expect(subject.fields).to eq({
        "params" => { "ref" => "alpha" },
        "status" => "pending"
      })

      subject.update_fields({ "status" => "success" })

      expect(subject.fields).to eq({
        "params" => { "ref" => "alpha" },
        "status" => "success"
      })
    end

    it "does nothing if the parameter is nil" do
      expect(subject.fields).to eq({
        "params" => { "ref" => "alpha" },
        "status" => "pending"
      })

      subject.update_fields(nil)

      expect(subject.fields).to eq({
        "params" => { "ref" => "alpha" },
        "status" => "pending"
      })
    end
  end

  context "#proceed!" do
    before do
      allow(engine).to receive(:participant).and_return(participant)
    end

    it "calls proceed on the workitem's participant" do
      expect(participant).to receive(:proceed).with(ruote_workitem)
      subject.proceed!
    end
  end
end
