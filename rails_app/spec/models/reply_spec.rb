require 'rails_helper'

RSpec.describe Reply, type: :model do
  describe "#preview" do
    it "returns a blockquote with the reply text" do
      reply = build(:reply, reply: "Hello world")
      expect(reply.preview).to include("<blockquote>Hello world</blockquote>")
    end

    it "truncates long replies" do
      long_text = "a" * 150
      reply = build(:reply, reply: long_text)
      expect(reply.preview).to include("...")
      expect(reply.preview.length).to be < 150
    end
  end
end
