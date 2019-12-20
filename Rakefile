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

task :require_bundler do
  $: << __dir__
  $: << File.join(__dir__, 'lib')
  ENV['BUNDLE_GEMFILE'] ||= File.join(__dir__, 'Gemfile')

  require 'rubygems'
  require 'bundler'

  raise <<~ERROR.chomp unless ENV['RACK_ENV']
    Can not require the application because the RACK_ENV has not been set.
    Please export the env to your environment and try again:

    export RACK_ENV=production
  ERROR

  Bundler.require(:default, ENV['RACK_ENV'].to_sym)
end

task require: :require_bundler do
  require 'config/initializers/figaro'
  require 'config/initializers/logger'
  require 'app/records'
  # require 'app/models'
  # require 'app/token'
  # require 'app/serializers'
  require 'app'
end

task console: :require do
  Bundler.require(:pry)
  binding.pry
end

# task 'token:admin' => :require do
#   puts Token.new(admin: true).generate_jwt
# end

# task 'token:user' => :require do
#   puts Token.new.generate_jwt
# end

# Creates the demo cluster used by the spec
task :'setup:demo-cluster' => :require do
  cluster = ClusterRecord.create(
    name: 'demo-cluster',
    level_params: {
      platform: 'demo',
      key: 'cluster',
      cluster: 'demo-cluster'
    }
  )

  nodes = (1..10).map do |idx|
    name = "node#{idx}"
    NodeRecord.create(
      name: name,
      level_params: {
        key: name,
        ip: "10.10.0.#{idx}"
      },
      relationships: { cluster: cluster }
    )
  end

  # NOTE: The odds/evens only look reversed because node01 is at index 0
  evens = nodes.each_with_index.reject { |_, i| i.even? }.map { |n, _| n }
  odds = nodes.each_with_index.select { |_, i| i.even? }.map { |n, _| n }

  GroupRecord.create(
    name: 'even',
    level_params: {
      key: 'even',
      even: true
    },
    relationships: { cluster: cluster, nodes: evens }
  )

  GroupRecord.create(
    name: 'odd',
    level_params: {
      key: 'odd',
      even: false
    },
    relationships: { cluster: cluster, nodes: odds }
  )

  GroupRecord.create(
    name: 'subnet',
    level_params: {
      key: 'subnet',
      subnet: '10.10.0.0/24'
    },
    relationships: { cluster: cluster, nodes: nodes }
  )
end

task :'drop:demo-cluster' => :require do
  cluster = ClusterRecord.includes(:nodes, :groups).find('.demo-cluster').first
  cluster.nodes.each(&:destroy)
  cluster.groups.each(&:destroy)
  cluster.destroy
end

