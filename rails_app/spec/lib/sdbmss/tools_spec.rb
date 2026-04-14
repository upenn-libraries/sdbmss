require 'tmpdir'
require 'fileutils'
require 'sdbmss/tools'

describe SDBMSS::Tools do
  describe '.truthy?' do
    it 'returns true for truthy strings' do
      expect(described_class.truthy?('true')).to be true
      expect(described_class.truthy?('1')).to be true
      expect(described_class.truthy?('YES')).to be true
    end

    it 'returns false for falsey strings' do
      expect(described_class.truthy?('false')).to be false
      expect(described_class.truthy?(nil)).to be false
    end
  end

  describe '.timestamp' do
    it 'returns UTC time in ISO-8601 format' do
      expect(described_class.timestamp).to match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/)
    end
  end

  describe '.sdbm_available?' do
    it 'returns true when endpoint returns HTTP 200' do
      response = instance_double('Net::HTTPResponse', code: '200')
      allow(Net::HTTP).to receive(:start).and_return(response)

      expect(described_class.sdbm_available?('sdbmss.localhost', timeout_seconds: 1, interval_seconds: 0)).to be true
    end

    it 'returns false when endpoint is unavailable' do
      allow(Net::HTTP).to receive(:start).and_raise(SocketError)

      expect(described_class.sdbm_available?('bad.localhost', timeout_seconds: 0, interval_seconds: 0)).to be false
    end
  end

  describe '#load_docker_environment!' do
    let(:tmpdir)     { Dir.mktmpdir }
    let(:rails_root) { File.join(tmpdir, 'rails_app') }
    let(:env_file)   { File.join(rails_root, '.env') }
    let(:env)        { {} }
    let(:tools) do
      t = described_class.new(env: env)
      allow(t).to receive(:rails_root).and_return(rails_root)
      t
    end

    before { FileUtils.mkdir_p(rails_root) }
    after  { FileUtils.remove_entry(tmpdir) }

    it 'loads .env values into env if missing' do
      File.write(env_file, "SDBMSS_APP_HOST=sdbmss.localhost\nCOMPOSE_PROJECT_NAME=sdbmss\n")
      tools.send(:load_docker_environment!)

      expect(env['SDBMSS_APP_HOST']).to eq('sdbmss.localhost')
      expect(env['COMPOSE_PROJECT_NAME']).to eq('sdbmss')
    end

    it 'does not overwrite keys already present in env' do
      File.write(env_file, "SDBMSS_APP_HOST=from-file\n")
      env['SDBMSS_APP_HOST'] = 'pre-existing'
      tools.send(:load_docker_environment!)

      expect(env['SDBMSS_APP_HOST']).to eq('pre-existing')
    end

    it 'splits only on the first = so values containing = are preserved' do
      File.write(env_file, "SECRET=abc=def==ghi\n")
      tools.send(:load_docker_environment!)

      expect(env['SECRET']).to eq('abc=def==ghi')
    end

    it 'skips empty lines and comment lines' do
      File.write(env_file, "\n# comment\nKEY=value\n")
      tools.send(:load_docker_environment!)

      expect(env.keys).to eq(['KEY'])
    end

    it 'raises with a helpful message when .env is missing' do
      expect { tools.send(:load_docker_environment!) }.to raise_error(RuntimeError, /docker-environment-sample/)
    end
  end

  describe '#verify_data_files!' do
    let(:tmpdir)     { Dir.mktmpdir }
    let(:rails_root) { File.join(tmpdir, 'rails_app') }
    let(:data_dir)   { File.join(rails_root, 'dev', 'data') }
    let(:tools) do
      t = described_class.new(env: {})
      allow(t).to receive(:rails_root).and_return(rails_root)
      t
    end

    before { FileUtils.mkdir_p(data_dir) }
    after  { FileUtils.remove_entry(tmpdir) }

    def create_data_archive; File.write(File.join(data_dir, 'sdbm_data.tgz'), ''); end
    def create_sql_archive;  File.write(File.join(data_dir, 'sdbm.sql.gz'),  ''); end

    it 'does not raise when both archive files exist' do
      create_data_archive
      create_sql_archive
      expect { tools.send(:verify_data_files!) }.not_to raise_error
    end

    it 'raises when the data archive is missing' do
      create_sql_archive
      expect { tools.send(:verify_data_files!) }.to raise_error(RuntimeError, /SDBM_DATA_ARCHIVE/)
    end

    it 'raises when the SQL archive is missing' do
      create_data_archive
      expect { tools.send(:verify_data_files!) }.to raise_error(RuntimeError, /SDBM_SQL_ARCHIVE/)
    end
  end

  describe '#rewrite_home_text!' do
    let(:tmpdir)    { Dir.mktmpdir }
    let(:html_path) { File.join(tmpdir, 'home_text.html') }
    let(:tools)     { described_class.new(env: { 'SDBMSS_APP_HOST' => 'sdbmss.localhost' }) }

    after { FileUtils.remove_entry(tmpdir) }

    it 'replaces hard-coded hostname with SDBMSS_APP_HOST' do
      File.write(html_path, '<a href="http://sdbm.library.upenn.edu/foo">link</a>')
      tools.send(:rewrite_home_text!, html_path)

      expect(File.read(html_path)).to include('sdbmss.localhost')
      expect(File.read(html_path)).not_to include('sdbm.library.upenn.edu')
    end

    it 'is a no-op when the file does not exist' do
      expect { tools.send(:rewrite_home_text!, '/nonexistent/home_text.html') }.not_to raise_error
    end

    it 'leaves the file unchanged when the hostname is not present' do
      original = '<p>No hostnames here</p>'
      File.write(html_path, original)
      tools.send(:rewrite_home_text!, html_path)

      expect(File.read(html_path)).to eq(original)
    end
  end

  describe '#hosts_mapping_present?' do
    let(:tools) { described_class.new(env: {}) }

    def stub_hosts(lines)
      allow(File).to receive(:readlines).with('/etc/hosts').and_return(lines)
    end

    it 'returns true for a simple ip+host line' do
      stub_hosts(["127.0.0.1 sdbmss.localhost\n"])
      expect(tools.send(:hosts_mapping_present?, 'sdbmss.localhost')).to be true
    end

    it 'returns true when host is one of several on a line' do
      stub_hosts(["127.0.0.1 host1 sdbmss.localhost host2\n"])
      expect(tools.send(:hosts_mapping_present?, 'sdbmss.localhost')).to be true
    end

    it 'returns true when a trailing comment is present' do
      stub_hosts(["127.0.0.1 sdbmss.localhost # my dev host\n"])
      expect(tools.send(:hosts_mapping_present?, 'sdbmss.localhost')).to be true
    end

    it 'returns false when the entry is commented out' do
      stub_hosts(["# 127.0.0.1 sdbmss.localhost\n"])
      expect(tools.send(:hosts_mapping_present?, 'sdbmss.localhost')).to be false
    end

    it 'returns false when the host is not present' do
      stub_hosts(["127.0.0.1 other.localhost\n"])
      expect(tools.send(:hosts_mapping_present?, 'sdbmss.localhost')).to be false
    end

    it 'returns false when /etc/hosts raises Errno::EACCES' do
      allow(File).to receive(:readlines).with('/etc/hosts').and_raise(Errno::EACCES)
      expect(tools.send(:hosts_mapping_present?, 'sdbmss.localhost')).to be false
    end
  end

  describe '#diagnose_host_mapping' do
    let(:out) { StringIO.new }

    def tools_with_host(host)
      described_class.new(env: { 'SDBMSS_APP_HOST' => host }, out: out)
    end

    it 'returns early without output when SDBMSS_APP_HOST is nil' do
      tools = described_class.new(env: {}, out: out)
      tools.diagnose_host_mapping
      expect(out.string).to be_empty
    end

    it 'returns early without output when SDBMSS_APP_HOST is empty' do
      tools = tools_with_host('')
      tools.diagnose_host_mapping
      expect(out.string).to be_empty
    end

    it 'logs a warning when host is not in /etc/hosts' do
      tools = tools_with_host('sdbmss.localhost')
      allow(tools).to receive(:hosts_mapping_present?).and_return(false)
      allow(Socket).to receive(:getaddrinfo)
      allow(TCPSocket).to receive(:new).and_return(double(close: nil))

      tools.diagnose_host_mapping

      expect(out.string).to include('127.0.0.1 sdbmss.localhost')
    end

    it 'logs a connectivity warning on SocketError' do
      tools = tools_with_host('sdbmss.localhost')
      allow(tools).to receive(:hosts_mapping_present?).and_return(true)
      allow(Socket).to receive(:getaddrinfo).and_raise(SocketError, 'getaddrinfo failed')

      tools.diagnose_host_mapping

      expect(out.string).to include('connectivity issue')
    end

    it 'logs a connectivity warning on Errno::ECONNREFUSED' do
      tools = tools_with_host('sdbmss.localhost')
      allow(tools).to receive(:hosts_mapping_present?).and_return(true)
      allow(Socket).to receive(:getaddrinfo)
      allow(TCPSocket).to receive(:new).and_raise(Errno::ECONNREFUSED)

      tools.diagnose_host_mapping

      expect(out.string).to include('connectivity issue')
    end

    it 'produces no warnings when host is mapped and reachable' do
      tools = tools_with_host('sdbmss.localhost')
      allow(tools).to receive(:hosts_mapping_present?).and_return(true)
      allow(Socket).to receive(:getaddrinfo)
      allow(TCPSocket).to receive(:new).and_return(double(close: nil))

      tools.diagnose_host_mapping

      expect(out.string).to be_empty
    end
  end

  describe '#clobber' do
    let(:tmpdir)     { Dir.mktmpdir }
    let(:rails_root) { File.join(tmpdir, 'rails_app') }
    let(:out)        { StringIO.new }
    let(:tools) do
      t = described_class.new(env: {}, out: out)
      allow(t).to receive(:rails_root).and_return(rails_root)
      allow(t).to receive(:load_docker_environment!)
      allow(t).to receive(:run_compose!)
      allow(t).to receive(:remove_custom_images!)
      allow(t).to receive(:run_command!)
      allow(t).to receive(:remove_local_files!)
      t
    end

    after { FileUtils.remove_entry(tmpdir) }

    it 'runs compose down, removes images, prunes docker, and removes files by default' do
      expect(tools).to receive(:run_compose!).with(%w[down -v])
      expect(tools).to receive(:remove_custom_images!)
      expect(tools).to receive(:run_command!).with(%w[docker system prune -af])
      expect(tools).to receive(:remove_local_files!)

      tools.clobber
    end

    it 'skips docker system prune when prune: false' do
      expect(tools).not_to receive(:run_command!).with(%w[docker system prune -af])

      tools.clobber(prune: false)
    end

    it 'skips file removal when files: false' do
      expect(tools).not_to receive(:remove_local_files!)

      tools.clobber(files: false)
    end
  end

  describe '#remove_local_files!' do
    let(:tmpdir)     { Dir.mktmpdir }
    let(:rails_root) { File.join(tmpdir, 'rails_app') }
    let(:out)        { StringIO.new }
    let(:tools) do
      t = described_class.new(env: {}, out: out)
      allow(t).to receive(:rails_root).and_return(rails_root)
      t
    end

    before { FileUtils.mkdir_p(rails_root) }
    after  { FileUtils.remove_entry(tmpdir) }

    it 'removes directories that exist' do
      dir = File.join(rails_root, 'tmp')
      FileUtils.mkdir_p(dir)

      tools.send(:remove_local_files!)

      expect(Dir.exist?(dir)).to be false
    end

    it 'skips directories that do not exist without raising' do
      expect { tools.send(:remove_local_files!) }.not_to raise_error
    end

    it 'logs removal for present dirs and skip for absent dirs' do
      FileUtils.mkdir_p(File.join(rails_root, 'tmp'))

      tools.send(:remove_local_files!)

      expect(out.string).to include('Removing tmp')
      expect(out.string).to include('.bundle not present; skipping')
    end
  end

  describe '#data_archive_path' do
    it 'defaults to rails_root/dev/data/sdbm_data.tgz' do
      tools = described_class.new(env: {})
      allow(tools).to receive(:rails_root).and_return('/app')

      expect(tools.send(:data_archive_path)).to eq('/app/dev/data/sdbm_data.tgz')
    end

    it 'uses SDBM_DATA_ARCHIVE when set' do
      tools = described_class.new(env: { 'SDBM_DATA_ARCHIVE' => '/mnt/data/custom.tgz' })
      allow(tools).to receive(:rails_root).and_return('/app')

      expect(tools.send(:data_archive_path)).to eq('/mnt/data/custom.tgz')
    end
  end

  describe '#sql_archive_path' do
    it 'defaults to rails_root/dev/data/sdbm.sql.gz' do
      tools = described_class.new(env: {})
      allow(tools).to receive(:rails_root).and_return('/app')

      expect(tools.send(:sql_archive_path)).to eq('/app/dev/data/sdbm.sql.gz')
    end

    it 'uses SDBM_SQL_ARCHIVE when set' do
      tools = described_class.new(env: { 'SDBM_SQL_ARCHIVE' => '/mnt/data/custom.sql.gz' })
      allow(tools).to receive(:rails_root).and_return('/app')

      expect(tools.send(:sql_archive_path)).to eq('/mnt/data/custom.sql.gz')
    end
  end
end

# AI Usage Disclosure: Designed and implemented by Claude Sonnet 4.6 (Anthropic).
