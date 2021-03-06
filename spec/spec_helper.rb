# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file is part of Render Server.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Render Server is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Render Server. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Render Server, please visit:
# https://github.com/openflighthpc/render-server
#===============================================================================

ENV['RACK_ENV'] = 'test'
ENV['jwt_shared_secret'] = 'SOME_TEST_TOKEN'

require 'rake'
load File.expand_path('../Rakefile', __dir__)
Rake::Task[:require].invoke

require 'fakefs/spec_helpers'
require 'hashie'
require 'json'
require 'vcr'

require 'fixtures/demo_cluster'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.filter_sensitive_data('[REDACTED]') do |interaction|
    interaction.request.headers['Authorization'].first
  end
end

module RSpecSinatraMixin
  include Rack::Test::Methods

  def app()
    Sinatra::Application.new
  end
end

# If you use RSpec 1.x you should use this instead:
RSpec.configure do |c|
	# Include the Sinatra helps into the application
	c.include RSpecSinatraMixin

  c.around(:each) do |example|
    # NOTE: *READ ME FUTURE DEVS*
    # The following line should be commented out *most of the time. This prevents VCR
    # from making any new requests that it doesn't recognised. In theory, the app should
    # make the same requests each time.
    #
    # * It is acceptable to uncomment the line when adding new specs IF you need to make
    # a new request. However please comment it out once you are done
    #
    # @vcr_record_mode = :new_episodes

    VCR.use_cassette(Figaro.env.remote_cluster!,
                     record: @vcr_record_mode || :once,
                     allow_playback_repeats: true) do
      FakeFS do
        FakeFS.clear!
        FakeFS::FileSystem.clone(File.join(__dir__, 'fixtures/vcr_cassettes'))
        FakeFS::FileSystem.clone(File.join(__dir__, '../app.rb'))
        FakeFS::FileSystem.clone(File.join(__dir__, '../app'))
        FakeFS::FileSystem.clone(File.join(__dir__, '../spec'))
        FakeFS::FileSystem.clone(Pry.config.history.file)

        # Clone ActiveSupport translations into the app
        $:.select { |p| p =~ /activesupport/ }
          .first
          .tap { |p| FakeFS::FileSystem.clone(File.join(p, 'active_support/locale/en.yml')) }

        # Clone ActiveModel translations into the app
        $:.select { |p| p =~ /activemodel/ }
          .first
          .tap { |p| FakeFS::FileSystem.clone(File.join(p, 'active_model/locale/en.yml')) }

        example.call
      end
    end
  end

  def reset_proxies
    @reset_proxies ||= ObjectSpace.each_object(Module)
                                  .select { |c| c.included_modules.include? HasProxies }
    @reset_proxies.each { |c| c.instance_variable_set(:@proxy_class, nil) }
    Topology::Cache.instance_variable_set(:@instance, nil)
  end

  def run_in_standalone
    reset_proxies
    ClimateControl.modify(remote_url: nil, topology_config: topology_path) do
      yield if block_given?
    end
    reset_proxies
  end

  def topology_path
    File.expand_path('fixtures/standalone_cluster.yaml', __dir__)
  end

  def topology
    Hashie::Mash.load(topology_path)
  end

  def admin_headers
    header 'Content-Type', 'application/vnd.api+json'
    header 'Accept', 'application/vnd.api+json'
    header 'Authorization', "Bearer #{Token.new(admin: true).generate_jwt}"
  end

  def user_headers
    header 'Content-Type', 'application/vnd.api+json'
    header 'Accept', 'application/vnd.api+json'
    header 'Authorization', "Bearer #{Token.new.generate_jwt}"
  end

  def parse_last_request_body
    Hashie::Mash.new(JSON.pase(last_request.body))
  end

  def parse_last_response_body
    Hashie::Mash.new(JSON.parse(last_response.body))
  end

  def last_request_error
    last_request.env['sinatra.error']
  end

  def error_pointers
    parse_last_response_body.errors.map { |e| e.source.pointer }
  end

  def build_rio(model)
    type = JSONAPI::Serializer.find_serializer(model, {}).type
    { type: type, id: model.id }
  end

  def build_payload(model, include_id: true, attributes: {}, relationships: {})
    serializer = JSONAPI::Serializer.find_serializer(model, {})
    rel_hash = relationships.each_with_object({}) do |(key, entity), hash|
      hash[key] = { data: nil }
      hash[key][:data] = if entity.is_a? Array
        entity.map { |e| build_rio(e) }
      else
        build_rio(entity)
      end
    end
    {
      data: {
        type: serializer.type,
        attributes: attributes,
        relationships: rel_hash
      }.tap do |hash|
        hash[:id] = model.id if include_id
      end
    }
  end

  def cluster_record
    ClusterRecord.find(".#{Figaro.env.remote_cluster!}").first
  end
end
