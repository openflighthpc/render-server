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

  # NOTE: *READ ME FUTURE DEVS*
  # The following line should be commented out *most of the time. This prevents VCR
  # from making any new requests that it doesn't recognised. In theory, the app should
  # make the same requests each time.
  #
  # * It is acceptable to uncomment the line when adding new specs IF you need to make
  # a new request. However please comment it out once you are done
  #
  # @vcr_record_mode = :new_episodes

  c.around(:each) do |example|
    FakeFS do
      FakeFS::FileSystem.clone(File.join(__dir__, 'fixtures/vcr_cassettes'))

      VCR.use_cassette(Figaro.env.remote_cluster!,
                       record: @vcr_record_mode || :once,
                       allow_playback_repeats: true) do
        example.call
      end
    end
  end

  def admin_headers
    header 'Content-Type', 'application/vnd.api+json'
    header 'Accept', 'application/vnd.api+json'
    # header 'Authorization', "Bearer #{Token.new(admin: true).generate_jwt}"
  end

  def user_headers
    header 'Content-Type', 'application/vnd.api+json'
    header 'Accept', 'application/vnd.api+json'
    # header 'Authorization', "Bearer #{Token.new.generate_jwt}"
  end

  def parse_last_request_body
    Hashie::Mash.new(JSON.pase(last_request.body))
  end

  def parse_last_response_body
    Hashie::Mash.new(JSON.parse(last_response.body))
  end

  def error_pointers
    parse_last_response_body.errors.map { |e| e.source.pointer }
  end

  def build_rio(model, fuzzy: true)
    type = JSONAPI::Serializer.find_serializer(model, {}).type
    { type: type, id: (fuzzy ? model.fuzzy_id : model.id) }
  end

  def build_payload(model, attributes: {}, relationships: {}, fuzzy: true)
    serializer = JSONAPI::Serializer.find_serializer(model, {})
    rel_hash = relationships.each_with_object({}) do |(key, entity), hash|
      hash[key] = { data: nil }
      hash[key][:data] = if entity.is_a? Array
        entity.map { |e| build_rio(e, fuzzy: fuzzy) }
      else
        build_rio(entity, fuzzy: fuzzy)
      end
    end
    {
      data: {
        type: serializer.type,
        attributes: attributes,
        relationships: rel_hash
      }.tap do |hash|
        next unless model.class.where(id: model.id.to_s).any?
        hash[:id] = fuzzy ? model.fuzzy_id : model.id
      end
    }
  end

  def cluster_record
    ClusterRecord.find(".#{Figaro.env.remote_cluster!}").first
  end
end
