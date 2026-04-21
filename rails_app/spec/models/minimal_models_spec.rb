require 'rails_helper'

RSpec.describe DericciRecordFlag, type: :model do
  it "has reasons" do
    expect(DericciRecordFlag.reasons).to be_an(Array)
    expect(DericciRecordFlag.reasons.first).to include("not relevant")
  end
end

RSpec.describe UserMessage, type: :model do
  it "belongs to private_message and user" do
    um = build(:user_message)
    expect(um).to respond_to(:private_message)
    expect(um).to respond_to(:user)
  end
end

RSpec.describe DericciGameRecord, type: :model do
  it "belongs to dericci_game and dericci_record" do
    dgr = DericciGameRecord.new
    expect(dgr).to respond_to(:dericci_game)
    expect(dgr).to respond_to(:dericci_record)
  end
end

RSpec.describe EntryChange, type: :model do
  it "validates presence of entry" do
    ec = build(:entry_change, entry: nil)
    expect(ec).not_to be_valid
  end
end
