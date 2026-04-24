require "rails_helper"

describe Download do

  let(:user) { create(:user) }

  def build_download(filename: "report.csv")
    download = Download.new(filename: filename, user: user)
    # skip the after_create delayed-destroy callback during unit tests
    allow(download).to receive(:delay).and_return(double("proxy", destroy: nil))
    download
  end

  def create_download(filename: "report.csv")
    dl = build_download(filename: filename)
    dl.save!(validate: false)
    dl
  end

  describe "#to_s" do
    it "returns the filename" do
      dl = build_download(filename: "export.csv")
      expect(dl.to_s).to eq("export.csv")
    end
  end

  describe "#get_path" do
    it "returns a path composed of id, username and filename" do
      dl = create_download(filename: "data.csv")
      expected = "#{dl.id}_#{user.username}_data.csv"
      expect(dl.get_path).to eq(expected)
    end
  end

  describe "#destroy" do
    context "when the associated file exists" do
      it "deletes the file before destroying the record" do
        dl = create_download(filename: "to_delete.csv")
        path = "tmp/#{dl.id}_#{user.username}_to_delete.csv"
        allow(File).to receive(:exist?).with(path).and_return(true)
        expect(File).to receive(:delete).with(path)
        dl.destroy
        expect(Download.where(id: dl.id)).to be_empty
      end
    end

    context "when the associated file does not exist" do
      it "destroys the record without attempting file deletion" do
        dl = create_download(filename: "missing.csv")
        path = "tmp/#{dl.id}_#{user.username}_missing.csv"
        allow(File).to receive(:exist?).with(path).and_return(false)
        expect(File).not_to receive(:delete)
        dl.destroy
        expect(Download.where(id: dl.id)).to be_empty
      end
    end
  end

end
