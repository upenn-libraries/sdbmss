require 'rails_helper'

RSpec.describe EntryArtist, type: :model do
  it_behaves_like "a TellBunny-enabled model"

  describe "callbacks" do
    it "ensures the associated name is marked as an artist" do
      name = create(:name, is_artist: false)
      create(:entry_artist, artist: name)
      expect(name.reload.is_artist).to be true
    end
  end

  describe "#format_role" do
    it "formats known roles" do
      artist = build(:entry_artist, role: "Arti")
      expect(artist.format_role).to eq("Artist")
    end

    it "returns the raw role if unknown" do
      artist = build(:entry_artist, role: "Unknown")
      expect(artist.format_role).to eq("Unknown")
    end
  end
end
