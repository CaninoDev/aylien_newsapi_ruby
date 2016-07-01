# Copyright 2016 Aylien, Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'

describe AylienNewsApi::ApiClient do
  context 'initialization' do
    context 'URL stuff' do
      context 'host' do
        it 'removes http from host' do
          AylienNewsApi.configure { |c| c.host = 'http://example.com' }
          expect(AylienNewsApi::Configuration.default.host).to eq('example.com')
        end

        it 'removes https from host' do
          AylienNewsApi.configure { |c| c.host = 'https://wookiee.com' }
          expect(AylienNewsApi::ApiClient.default.config.host).to eq('wookiee.com')
        end

        it 'removes trailing path from host' do
          AylienNewsApi.configure { |c| c.host = 'hobo.com/v4' }
          expect(AylienNewsApi::Configuration.default.host).to eq('hobo.com')
        end
      end

      context 'base_path' do
        it "prepends a slash to base_path" do
          AylienNewsApi.configure { |c| c.base_path = 'v4/dog' }
          expect(AylienNewsApi::Configuration.default.base_path).to eq('/v4/dog')
        end

        it "doesn't prepend a slash if one is already there" do
          AylienNewsApi.configure { |c| c.base_path = '/v4/dog' }
          expect(AylienNewsApi::Configuration.default.base_path).to eq('/v4/dog')
        end

        it "ends up as a blank string if nil" do
          AylienNewsApi.configure { |c| c.base_path = nil }
          expect(AylienNewsApi::Configuration.default.base_path).to eq('')
        end
      end
    end
  end

  describe "#update_params_for_auth!" do
    it "sets header api-key parameter with prefix" do
      AylienNewsApi.configure do |c|
        c.api_key_prefix['X-AYLIEN-NewsAPI-Application-ID'] = 'PREFIX'
        c.api_key['X-AYLIEN-NewsAPI-Application-ID'] = 'special-key'
      end

      api_client = AylienNewsApi::ApiClient.new

      config2 = AylienNewsApi::Configuration.new do |c|
        c.api_key_prefix['X-AYLIEN-NewsAPI-Application-ID'] = 'PREFIX2'
        c.api_key['X-AYLIEN-NewsAPI-Application-ID'] = 'special-key2'
      end
      api_client2 = AylienNewsApi::ApiClient.new(config2)

      auth_names = ['app_id']

      header_params = {}
      query_params = {}
      api_client.update_params_for_auth! header_params, query_params, auth_names
      expect(header_params).to eq({'X-AYLIEN-NewsAPI-Application-ID' => 'PREFIX special-key'})
      expect(query_params).to eq({})

      header_params = {}
      query_params = {}
      api_client2.update_params_for_auth! header_params, query_params, auth_names
      expect(header_params).to eq({'X-AYLIEN-NewsAPI-Application-ID' => 'PREFIX2 special-key2'})
      expect(query_params).to eq({})
    end

    it "sets header api-key parameter without prefix" do
      AylienNewsApi.configure do |c|
        c.api_key_prefix['X-AYLIEN-NewsAPI-Application-ID'] = nil
        c.api_key['X-AYLIEN-NewsAPI-Application-ID'] = 'special-key'
      end

      api_client = AylienNewsApi::ApiClient.new

      header_params = {}
      query_params = {}
      auth_names = ['app_id']
      api_client.update_params_for_auth! header_params, query_params, auth_names
      expect(header_params).to eq({'X-AYLIEN-NewsAPI-Application-ID' => 'special-key'})
      expect(query_params).to eq({})
    end
  end

  describe "params_encoding in #build_request" do
    let(:config) { AylienNewsApi::Configuration.new }
    let(:api_client) { AylienNewsApi::ApiClient.new(config) }

    it "defaults to multi" do
      expect(AylienNewsApi::Configuration.default.params_encoding).to eq(:multi)
      expect(config.params_encoding).to eq(:multi)

      request = api_client.build_request(:get, '/test')
      expect(request.options[:params_encoding]).to eq(:multi)
    end

    it "can be customized" do
      config.params_encoding = nil
      request = api_client.build_request(:get, '/test')
      expect(request.options[:params_encoding]).to eq(nil)
    end
  end

  describe "timeout in #build_request" do
    let(:config) { AylienNewsApi::Configuration.new }
    let(:api_client) { AylienNewsApi::ApiClient.new(config) }

    it "defaults to 0" do
      expect(AylienNewsApi::Configuration.default.timeout).to eq(0)
      expect(config.timeout).to eq(0)

      request = api_client.build_request(:get, '/test')
      expect(request.options[:timeout]).to eq(0)
    end

    it "can be customized" do
      config.timeout = 100
      request = api_client.build_request(:get, '/test')
      expect(request.options[:timeout]).to eq(100)
    end
  end

  describe "#deserialize" do
    it "handles Array<Integer>" do
      api_client = AylienNewsApi::ApiClient.new
      headers = {'Content-Type' => 'application/json'}
      response = double('response', headers: headers, body: '[12, 34]')
      data = api_client.deserialize(response, 'Array<Integer>')
      expect(data).to be_instance_of(Array)
      expect(data).to eq([12, 34])
    end

    it "handles Array<Array<Integer>>" do
      api_client = AylienNewsApi::ApiClient.new
      headers = {'Content-Type' => 'application/json'}
      response = double('response', headers: headers, body: '[[12, 34], [56]]')
      data = api_client.deserialize(response, 'Array<Array<Integer>>')
      expect(data).to be_instance_of(Array)
      expect(data).to eq([[12, 34], [56]])
    end

    it "handles Hash<String, String>" do
      api_client = AylienNewsApi::ApiClient.new
      headers = {'Content-Type' => 'application/json'}
      response = double('response', headers: headers, body: '{"message": "Hello"}')
      data = api_client.deserialize(response, 'Hash<String, String>')
      expect(data).to be_instance_of(Hash)
      expect(data).to eq({:message => 'Hello'})
    end

    it "handles Hash<String, Story>" do
      api_client = AylienNewsApi::ApiClient.new
      headers = {'Content-Type' => 'application/json'}
      response = double('response', headers: headers, body: '{"story": {"id": 1}}')
      data = api_client.deserialize(response, 'Hash<String, Story>')
      expect(data).to be_instance_of(Hash)
      expect(data.keys).to eq([:story])

      story = data[:story]
      expect(story).to be_instance_of(AylienNewsApi::Story)
      expect(story.id).to eq(1)
    end

    it "handles Hash<String, Hash<String, Story>>" do
      api_client = AylienNewsApi::ApiClient.new
      headers = {'Content-Type' => 'application/json'}
      response = double('response', headers: headers, body: '{"data": {"story": {"id": 1}}}')
      result = api_client.deserialize(response, 'Hash<String, Hash<String, Story>>')
      expect(result).to be_instance_of(Hash)
      expect(result.keys).to match_array([:data])

      data = result[:data]
      expect(data).to be_instance_of(Hash)
      expect(data.keys).to match_array([:story])

      story = data[:story]
      expect(story).to be_instance_of(AylienNewsApi::Story)
      expect(story.id).to eq(1)
    end
  end

  describe "#object_to_hash" do
    it "ignores nils and includes empty arrays" do
      api_client = AylienNewsApi::ApiClient.new
      story = AylienNewsApi::Story.new
      story.id = 1
      story.title = ''
      story.published_at = nil
      story.body = nil
      story.hashtags = []
      expected = {id: 1, title: '', hashtags: []}
      expect(api_client.object_to_hash(story)).to eq(expected)
    end
  end

  describe "#build_collection_param" do
    let(:param) { ['aa', 'bb', 'cc'] }
    let(:api_client) { AylienNewsApi::ApiClient.new }

    it "works for csv" do
      expect(api_client.build_collection_param(param, :csv)).to eq('aa,bb,cc')
    end

    it "works for ssv" do
      expect(api_client.build_collection_param(param, :ssv)).to eq('aa bb cc')
    end

    it "works for tsv" do
      expect(api_client.build_collection_param(param, :tsv)).to eq("aa\tbb\tcc")
    end

    it "works for pipes" do
      expect(api_client.build_collection_param(param, :pipes)).to eq('aa|bb|cc')
    end

    it "works for multi" do
      expect(api_client.build_collection_param(param, :multi)).to eq(['aa', 'bb', 'cc'])
    end

    it "fails for invalid collection format" do
      expect(proc { api_client.build_collection_param(param, :INVALID) }).to raise_error(RuntimeError, 'unknown collection format: :INVALID')
    end
  end

  describe "#json_mime?" do
    let(:api_client) { AylienNewsApi::ApiClient.new }

    it "works" do
      expect(api_client.json_mime?(nil)).to eq false
      expect(api_client.json_mime?('')).to eq false

      expect(api_client.json_mime?('application/json')).to eq true
      expect(api_client.json_mime?('application/json; charset=UTF8')).to eq true
      expect(api_client.json_mime?('APPLICATION/JSON')).to eq true

      expect(api_client.json_mime?('application/xml')).to eq false
      expect(api_client.json_mime?('text/plain')).to eq false
      expect(api_client.json_mime?('application/jsonp')).to eq false
    end
  end

  describe "#select_header_accept" do
    let(:api_client) { AylienNewsApi::ApiClient.new }

    it "works" do
      expect(api_client.select_header_accept(nil)).to be_nil
      expect(api_client.select_header_accept([])).to be_nil

      expect(api_client.select_header_accept(['application/json'])).to eq('application/json')
      expect(api_client.select_header_accept(['application/xml', 'application/json; charset=UTF8'])).to eq('application/json; charset=UTF8')
      expect(api_client.select_header_accept(['APPLICATION/JSON', 'text/html'])).to eq('APPLICATION/JSON')

      expect(api_client.select_header_accept(['application/xml'])).to eq('application/xml')
      expect(api_client.select_header_accept(['text/html', 'application/xml'])).to eq('text/html,application/xml')
    end
  end

  describe "#select_header_content_type" do
    let(:api_client) { AylienNewsApi::ApiClient.new }

    it "works" do
      expect(api_client.select_header_content_type(nil)).to eq('application/json')
      expect(api_client.select_header_content_type([])).to eq('application/json')

      expect(api_client.select_header_content_type(['application/json'])).to eq('application/json')
      expect(api_client.select_header_content_type(['application/xml', 'application/json; charset=UTF8'])).to eq('application/json; charset=UTF8')
      expect(api_client.select_header_content_type(['APPLICATION/JSON', 'text/html'])).to eq('APPLICATION/JSON')
      expect(api_client.select_header_content_type(['application/xml'])).to eq('application/xml')
      expect(api_client.select_header_content_type(['text/plain', 'application/xml'])).to eq('text/plain')
    end
  end

  describe "#sanitize_filename" do
    let(:api_client) { AylienNewsApi::ApiClient.new }

    it "works" do
      expect(api_client.sanitize_filename('sun')).to eq('sun')
      expect(api_client.sanitize_filename('sun.gif')).to eq('sun.gif')
      expect(api_client.sanitize_filename('../sun.gif')).to eq('sun.gif')
      expect(api_client.sanitize_filename('/var/tmp/sun.gif')).to eq('sun.gif')
      expect(api_client.sanitize_filename('./sun.gif')).to eq('sun.gif')
      expect(api_client.sanitize_filename('..\sun.gif')).to eq('sun.gif')
      expect(api_client.sanitize_filename('\var\tmp\sun.gif')).to eq('sun.gif')
      expect(api_client.sanitize_filename('c:\var\tmp\sun.gif')).to eq('sun.gif')
      expect(api_client.sanitize_filename('.\sun.gif')).to eq('sun.gif')
    end
  end
end
