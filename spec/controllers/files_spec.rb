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
    context 'with a single  filter' do
      {
        '[ids]' => -> { template.id },
        '[node.ids]' => -> { node.name },
        '[node.group-ids]' => -> { group.name },
        '[group.ids]' => -> { group.name },
        '[cluster]' => -> { true },
        '[node.all]' => -> { true },
        '[group.all]' => -> { true }
      }.each do |filter, value|
        it "returns an empty set: #{filter}" do
          template.save
          other_template.save
          admin_headers
          get "/files?filter#{filter}=#{instance_exec(&value)}"
          expect(parse_last_response_body.data).to be_empty
        end
      end
    end

    context 'when requesting a single template with context' do
      let(:base_params) { "include=context&filter[ids]=#{template.id}" }

      before { template.save }

      it 'can get multiple nodes' do
        nodes = [demo_cluster.nodes.first, demo_cluster.nodes.last]
        nodes_param = "filter[node.ids]=#{ nodes.map { |n| n.name }.join(',') }"
        admin_headers
        get "/files?#{base_params}&#{nodes_param}"
        returned_node_ids = parse_last_response_body.included.map(&:id)
        expect(returned_node_ids).to contain_exactly(*nodes.map(&:name))
      end

      it 'can get nodes in multiple groups' do
        groups = demo_cluster.groups.select { |g| ['even', 'odd'].include? g.name }
        groups_param = "filter[node.group-ids]=#{ groups.map { |g| g.name }.join(',') }"
        nodes = demo_cluster.nodes
        admin_headers
        get "/files?#{base_params}&#{groups_param}"
        returned_node_ids = parse_last_response_body.included.map(&:id)
        expect(returned_node_ids).to contain_exactly(*nodes.map(&:name))
      end

      it 'can get all the nodes' do
        nodes = demo_cluster.nodes
        admin_headers
        get "/files?#{base_params}&filter[node.all]=true"
        returned_node_ids = parse_last_response_body.included.map(&:id)
        expect(returned_node_ids).to contain_exactly(*nodes.map(&:name))
      end

      it 'can get multiple groups' do
        groups = demo_cluster.groups.select { |g| ['even', 'odd'].include? g.name }
        groups_param = "filter[group.ids]=#{ groups.map { |g| g.name }.join(',') }"
        admin_headers
        get "files?#{base_params}&#{groups_param}"
        returned_group_ids = parse_last_response_body.included.map(&:id)
        expect(returned_group_ids).to contain_exactly(*groups.map(&:name))
      end

      it 'can get all the groups' do
        groups = demo_cluster.groups
        groups_param = 'filter[group.all]=true'
        admin_headers
        get "files?#{base_params}&#{groups_param}"
        returned_group_ids = parse_last_response_body.included.map(&:id)
        expect(returned_group_ids).to contain_exactly(*groups.map(&:name))
      end

      it 'can get the cluster' do
        cluster_param = 'filter[cluster]=all'
        admin_headers
        get "files?#{base_params}&#{cluster_param}"
        returned_cluster_ids = parse_last_response_body.included.map(&:id)
        expect(returned_cluster_ids).to contain_exactly('default')
      end
    end

    ['node.ids', 'node.group-ids', 'group.ids'].each do |filter|
      describe "when requesting a missing resource via '#{filter}'" do
        before do
          template.save
          admin_headers
          get "files?filter[ids]=#{template.id}&filter[#{filter}]=missing"
        end

        it 'returns success' do
          expect(last_response).to be_successful
        end

        it 'returns a blank list' do
          expect(parse_last_response_body.data).to be_empty
        end
      end
    end
  end
end

