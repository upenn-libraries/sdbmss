require 'sdbmss/tools_cli'

describe SDBMSS::ToolsCLI do
  describe '#parse!' do
    it 'parses start with --force-rebuild' do
      cli = described_class.new(argv: %w[start --force-rebuild])
      command = cli.parse!

      expect(command.name).to eq('start')
      expect(command.options[:force_rebuild]).to be true
    end

    it 'parses start without flags (force_rebuild: false)' do
      cli = described_class.new(argv: %w[start])
      command = cli.parse!

      expect(command.name).to eq('start')
      expect(command.options[:force_rebuild]).to be false
    end

    it 'parses build-image options' do
      cli = described_class.new(argv: %w[build-image --url https://example.com/repo.git --image-name app --tag dev --force])
      command = cli.parse!

      expect(command.name).to eq('build-image')
      expect(command.options).to include(url: 'https://example.com/repo.git', image_name: 'app', tag: 'dev', force: true)
    end

    %w[stop rebuild setup setup-assets setup-db setup-jena].each do |cmd|
      it "parses #{cmd} with no options" do
        cli = described_class.new(argv: [cmd])
        command = cli.parse!

        expect(command.name).to eq(cmd)
        expect(command.options).to eq({})
      end
    end

    it 'parses clobber with no flags (prune: true, files: true)' do
      cli = described_class.new(argv: %w[clobber])
      command = cli.parse!

      expect(command.name).to eq('clobber')
      expect(command.options).to include(prune: true, files: true)
    end

    it 'parses clobber --no-prune' do
      cli = described_class.new(argv: %w[clobber --no-prune])
      command = cli.parse!

      expect(command.options[:prune]).to be false
      expect(command.options[:files]).to be true
    end

    it 'parses clobber --no-files' do
      cli = described_class.new(argv: %w[clobber --no-files])
      command = cli.parse!

      expect(command.options[:prune]).to be true
      expect(command.options[:files]).to be false
    end

    it 'parses clobber --no-prune --no-files' do
      cli = described_class.new(argv: %w[clobber --no-prune --no-files])
      command = cli.parse!

      expect(command.options).to include(prune: false, files: false)
    end

    it 'parses clean without flags (scope: :containers)' do
      cli = described_class.new(argv: %w[clean])
      command = cli.parse!

      expect(command.name).to eq('clean')
      expect(command.options[:scope]).to eq(:containers)
    end

    it 'parses clean --all (scope: :all)' do
      cli = described_class.new(argv: %w[clean --all])
      command = cli.parse!

      expect(command.name).to eq('clean')
      expect(command.options[:scope]).to eq(:all)
    end

    %w[help -h --help].each do |flag|
      it "parses #{flag} as help command" do
        cli = described_class.new(argv: [flag])
        expect(cli.parse!.name).to eq('help')
      end
    end

    it 'raises on missing command' do
      cli = described_class.new(argv: [])
      expect { cli.parse! }.to raise_error(ArgumentError)
    end

    it 'raises on unknown command' do
      cli = described_class.new(argv: %w[frobnicate])
      expect { cli.parse! }.to raise_error(ArgumentError, /Unknown command/)
    end

    it 'raises on unexpected trailing args for simple commands' do
      cli = described_class.new(argv: %w[stop unexpected-arg])
      expect { cli.parse! }.to raise_error(ArgumentError, /Unexpected arguments/)
    end

    it 'raises when build-image --url is missing' do
      cli = described_class.new(argv: %w[build-image --image-name myapp])
      expect { cli.parse! }.to raise_error(ArgumentError, /--url is required/)
    end

    it 'raises when build-image --image-name is missing' do
      cli = described_class.new(argv: %w[build-image --url https://example.com/repo.git])
      expect { cli.parse! }.to raise_error(ArgumentError, /--image-name is required/)
    end
  end

  describe '#run' do
    let(:tools) { instance_double(SDBMSS::Tools) }
    let(:out)   { StringIO.new }
    let(:err)   { StringIO.new }

    before { allow(SDBMSS::Tools).to receive(:new).and_return(tools) }

    it 'calls tools.start with force_rebuild: false for plain start' do
      expect(tools).to receive(:start).with(force_rebuild: false)
      described_class.new(argv: %w[start], out: out, err: err).run
    end

    it 'calls tools.start with force_rebuild: true for start --force-rebuild' do
      expect(tools).to receive(:start).with(force_rebuild: true)
      described_class.new(argv: %w[start --force-rebuild], out: out, err: err).run
    end

    it 'calls tools.stop for stop' do
      expect(tools).to receive(:stop)
      described_class.new(argv: %w[stop], out: out, err: err).run
    end

    it 'calls tools.clean(scope: :containers) for clean' do
      expect(tools).to receive(:clean).with(scope: :containers)
      described_class.new(argv: %w[clean], out: out, err: err).run
    end

    it 'calls tools.clean(scope: :all) for clean --all' do
      expect(tools).to receive(:clean).with(scope: :all)
      described_class.new(argv: %w[clean --all], out: out, err: err).run
    end

    it 'calls tools.clobber with defaults for plain clobber' do
      expect(tools).to receive(:clobber).with(prune: true, files: true)
      described_class.new(argv: %w[clobber], out: out, err: err).run
    end

    it 'calls tools.clobber with prune: false for clobber --no-prune' do
      expect(tools).to receive(:clobber).with(prune: false, files: true)
      described_class.new(argv: %w[clobber --no-prune], out: out, err: err).run
    end

    it 'calls tools.clobber with files: false for clobber --no-files' do
      expect(tools).to receive(:clobber).with(prune: true, files: false)
      described_class.new(argv: %w[clobber --no-files], out: out, err: err).run
    end

    it 'calls tools.rebuild for rebuild' do
      expect(tools).to receive(:rebuild)
      described_class.new(argv: %w[rebuild], out: out, err: err).run
    end

    it 'calls tools.setup for setup' do
      expect(tools).to receive(:setup)
      described_class.new(argv: %w[setup], out: out, err: err).run
    end

    it 'calls tools.setup_assets for setup-assets' do
      expect(tools).to receive(:setup_assets)
      described_class.new(argv: %w[setup-assets], out: out, err: err).run
    end

    it 'calls tools.setup_db for setup-db' do
      expect(tools).to receive(:setup_db)
      described_class.new(argv: %w[setup-db], out: out, err: err).run
    end

    it 'calls tools.setup_jena for setup-jena' do
      expect(tools).to receive(:setup_jena)
      described_class.new(argv: %w[setup-jena], out: out, err: err).run
    end

    it 'calls tools.build_image with the correct options' do
      expect(tools).to receive(:build_image).with(
        url: 'https://example.com/repo.git',
        image_name: 'myapp',
        tag: 'latest',
        force: false
      )
      described_class.new(
        argv: %w[build-image --url https://example.com/repo.git --image-name myapp],
        out: out, err: err
      ).run
    end

    it 'prints help text and returns 0 for help' do
      result = described_class.new(argv: %w[help], out: out, err: err).run

      expect(result).to eq(0)
      expect(out.string).to include('Usage:')
    end

    it 'returns 0 on success' do
      allow(tools).to receive(:stop)
      result = described_class.new(argv: %w[stop], out: out, err: err).run

      expect(result).to eq(0)
    end

    it 'returns 1 and writes error details to err on StandardError' do
      allow(tools).to receive(:stop).and_raise(StandardError, 'something broke')
      result = described_class.new(argv: %w[stop], out: out, err: err).run

      expect(result).to eq(1)
      expect(err.string).to include('something broke')
    end

    it 'returns 1 and writes error message to err on ArgumentError' do
      result = described_class.new(argv: %w[unknown-cmd], out: out, err: err).run

      expect(result).to eq(1)
      expect(err.string).to include('ERROR')
    end
  end
end

# AI Usage Disclosure: Designed and implemented by Claude Sonnet 4.6 (Anthropic).
