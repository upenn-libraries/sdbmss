require 'sdbmss/tools_cli'

describe SDBMSS::ToolsCLI do
  describe '#parse!' do
    it 'parses start with force' do
      cli = described_class.new(argv: %w[start --force])
      command = cli.parse!

      expect(command.name).to eq('start')
      expect(command.options[:force]).to be true
    end

    it 'parses build-image options' do
      cli = described_class.new(argv: %w[build-image --url https://example.com/repo.git --image-name app --tag dev --force])
      command = cli.parse!

      expect(command.name).to eq('build-image')
      expect(command.options).to include(url: 'https://example.com/repo.git', image_name: 'app', tag: 'dev', force: true)
    end

    it 'raises on missing command' do
      cli = described_class.new(argv: [])
      expect { cli.parse! }.to raise_error(ArgumentError)
    end
  end
end
