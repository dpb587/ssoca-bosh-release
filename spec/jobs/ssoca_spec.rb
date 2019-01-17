require 'rspec'
require 'json'
require 'bosh/template/test'

describe 'ssoca' do
  let(:release) { Bosh::Template::Test::ReleaseDir.new(File.join(File.dirname(__FILE__), '../..')) }
  let(:job) { release.job('ssoca') }
  let(:properties) { minimum_properties }
  let(:minimum_properties) do
    {
      'env' => {
        'url' => 'http://localhost:18705',
      },
      'auth' => {
        'type' => 'ignored',
        'options' => {},
      },
      'certauths' => [],
    }
  end

  describe 'config/bpm.yml' do
    let(:template) { job.template('config/bpm.yml') }
    let(:parsed_rendered_template) { JSON.parse(template.render(properties)) }

    it 'renders' do
      expect(parsed_rendered_template).to eq({
        'processes' => [
          {
            'name' => 'ssoca',
            'executable' => '/var/vcap/jobs/ssoca/bin/exec',
            'capabilities' => [],
            'additional_volumes' => [],
          },
        ],
      })
    end

    context 'running privileged ports' do
      let(:properties) do
        minimum_properties.merge({
          'server' => {
            'port' => 443,
          },
        })
      end

      it 'includes NET_BIND_SERVICE capabilities' do
        expect(parsed_rendered_template['processes'][0]['capabilities']).to eq(['NET_BIND_SERVICE'])
      end
    end

    context 'services requiring mounts' do
      let(:properties) do
        minimum_properties.merge({
          'services' => [
            {
              'type' => 'docroot',
              'options' => {
                'path' => '/var/vcap/packages/my-custom-ui',
              },
            },
            {
              'type' => 'download',
              'options' => {
                'glob' => '/var/vcap/packages/my-custom-binaries/ssoca-client-*',
              },
            },
            {
              'type' => 'download',
              'options' => {
                'glob' => '/var/vcap/packages/my-custom-downloads/public-*/*',
              },
            },
          ],
        })
      end

      it 'includes docroot and download paths' do
        expect(parsed_rendered_template['processes'][0]['additional_volumes']).to eq([
          {
            'path' => '/var/vcap/packages/my-custom-ui',
          },
          {
            'path' => '/var/vcap/packages/my-custom-binaries',
          },
          {
            'path' => '/var/vcap/packages/my-custom-downloads',
          },
        ])
      end
    end
  end

  describe 'etc/server.conf' do
    let(:template) { job.template('etc/server.conf') }
    let(:parsed_rendered_template) { JSON.parse(template.render(properties)) }

    context 'customized robots.txt' do
      let(:properties) {
        minimum_properties.merge({
          'server' => {
            'robotstxt' => 'humans.txt',
          },
        })
      }

      it 'is configurable' do
        expect(parsed_rendered_template['server']['robotstxt']).to eq('humans.txt')
      end
    end
  end
end
