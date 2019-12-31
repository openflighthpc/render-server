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

require 'spec_helper'

RSpec.describe '/files' do
  let(:template) do
    Template.new name:    'test',
                 type:    'test',
                 payload: '%key%'
  end
  let(:other_template) do
    Template.new name:    'other',
                 type:    'other'
  end

  let(:node) do
    demo_cluster.nodes.first
  end
  let(:group) do
    demo_cluster.groups.first
  end

  let(:demo_cluster) { DemoCluster.new(ids: true) }

  describe 'Show#GET' do
    it 'can get a template for a node' do
      template.save
      id = "#{template.id}.#{node.name}.nodes"
      admin_headers
      get "/files/#{id}"
      expect(last_response).to be_successful
    end
  end

  describe 'Index#GET' do
    {
      '[ids]' => '#{template.id}',
      '[node.ids]' => '#{node.id}',
      '[node.group-ids]' => '#{group.id}',
      '[group.ids]' => '#{group.id}',
      '[cluster]' => 'true',
      '[node.all]' => 'true',
      '[group.all]' => 'true'
    }.each do |filter, key|
      it "returns an empty set with single fitler: #{filter}" do
        template.save
        other_template.save
        admin_headers
        get "/files?filter#{filter}=#{eval key}"
        expect(parse_last_response_body.data).to be_empty
      end
    end
  end
end

