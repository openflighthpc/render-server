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

  # Turns FakeFS off if running in test mode. The gem isn't installed in production
  FakeFS.deactivate! if ENV['RACK_ENV'] == 'test'
end

task require: :require_bundler do
  require 'config/initializers/figaro'
  require 'config/initializers/logger'
  require 'app/records'
  require 'app/models'
  require 'app/proxies'
  require 'app/token'
  require 'app/serializers'
  require 'app'
end

task console: :require do
  Bundler.require(:default, ENV['RACK_ENV'].to_sym, :pry)
  binding.pry
end

task 'token:admin', [:days] => :require do |task, args|
  token = Token.new(admin: true)
               .tap { |t| t.exp_days = args[:days].to_i if args[:days] }
  puts token.generate_jwt
end

task 'token:user', [:days] => :require do |task, args|
  token = Token.new.tap { |t| t.exp_days = args[:days].to_i if args[:days] }
  puts token.generate_jwt
end

# Creates the demo cluster used by the spec
task :'cluster:setup' => :require do
  raise 'Can not setup cluster in production' if Figaro.env.RACK_ENV! == 'production'
  require_relative File.join(__dir__, 'spec/fixtures/demo_cluster.rb')

  demo = DemoCluster.new

  demo.cluster.save
  demo.nodes.each(&:save)
  demo.groups.each(&:save)
end

task :'cluster:drop' => :require do
  raise 'Can not drop cluster in production' if Figaro.env.RACK_ENV! == 'production'

  cluster = ClusterRecord.includes(:nodes, :groups)
                         .find(".#{Figaro.env.remote_cluster!}")
                         .first
  cluster.nodes.each(&:destroy)
  cluster.groups.each(&:destroy)
  cluster.destroy
end

