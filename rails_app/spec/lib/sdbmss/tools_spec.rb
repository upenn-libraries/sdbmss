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
    it 'loads .docker-environment values into env if missing' do
      Dir.mktmpdir do |tmpdir|
        rails_root = File.join(tmpdir, 'rails_app')
        FileUtils.mkdir_p(File.join(rails_root, 'lib', 'sdbmss'))
        File.write(File.join(rails_root, '.docker-environment'), "SDBMSS_APP_HOST=sdbmss.localhost\nCOMPOSE_PROJECT_NAME=sdbmss\n")

        env = {}
        tools = described_class.new(env: env)
        allow(tools).to receive(:rails_root).and_return(rails_root)

        tools.send(:load_docker_environment!)

        expect(env['SDBMSS_APP_HOST']).to eq('sdbmss.localhost')
        expect(env['COMPOSE_PROJECT_NAME']).to eq('sdbmss')
      end
    end
  end
end
