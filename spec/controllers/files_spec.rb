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
                 payload: '%key%'
  end
  let(:other_template) do
    Template.new name:    'other'
  end

  let(:node) do
    demo_cluster.nodes.first
  end
  let(:group) do
    demo_cluster.groups.first
  end

  let(:demo_cluster) { DemoCluster.new(ids: true) }

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

      context 'when requesting nodes by group' do
        let(:groups) { demo_cluster.groups.select { |g| ['even', 'odd'].include? g.name } }
        let(:nodes) { demo_cluster.nodes }

        before do
          groups_param = "filter[node.group-ids]=#{ groups.map { |g| g.name }.join(',') }"
          admin_headers
          get "/files?#{base_params}&#{groups_param}"
        end

        context 'when in standalone mode' do
          around(:all) { |e| run_in_standalone(&e) }

          it 'returns an empty list when requesting nodes by group' do
            expect(parse_last_response_body.data).to be_empty
          end
        end

        context 'when in upstream mode' do
          it 'can get nodes in multiple groups' do
            returned_node_ids = parse_last_response_body.included.map(&:id)
            expect(returned_node_ids).to contain_exactly(*nodes.map(&:name))
          end
        end
      end

      context 'when using node.ids' do
        before do
          admin_headers
          nodes_param = "filter[node.ids]=#{ nodes.join(',') }"
          get "/files?#{base_params}&#{nodes_param}"
        end

        context 'when in upstream mode' do
          let(:nodes) { [demo_cluster.nodes.first.name, demo_cluster.nodes.last.name] }

          it 'can get multiple nodes' do
            returned_node_ids = parse_last_response_body.included.map(&:id)
            expect(returned_node_ids).to contain_exactly(*nodes)
          end
        end

        context 'when in standalone mode' do
          let(:nodes) { [topology.nodes.keys.first, topology.nodes.keys.last] }

          around(:all) { |e| run_in_standalone(&e) }

          it 'can get standalone nodes' do
            returned_node_ids = parse_last_response_body.included.map(&:id)
            expect(returned_node_ids).to contain_exactly(*nodes)
          end
        end
      end

      context 'when using node.all' do
        before do
          admin_headers
          get "/files?#{base_params}&filter[node.all]=true"
        end

        context 'when in upstream mode' do
          it 'can get all the nodes' do
            nodes = demo_cluster.nodes
            returned_node_ids = parse_last_response_body.included.map(&:id)
            expect(returned_node_ids).to contain_exactly(*nodes.map(&:name))
          end
        end

        context 'when in standalone mode' do
          around(:all) { |e| run_in_standalone(&e) }

          it 'returns the topology nodes' do
            returned_node_ids = parse_last_response_body.included.map(&:id)
            expect(returned_node_ids).to contain_exactly(*topology.nodes.keys)
          end
        end
      end

      context 'when using group.ids' do
        let(:groups) { demo_cluster.groups.select { |g| ['even', 'odd'].include? g.name } }

        before do
          admin_headers
          get "files?#{base_params}&filter[group.ids]=#{ groups.map { |g| g.name }.join(',') }"
        end

        context 'when in upstream mode' do
          it 'can get multiple groups' do
            returned_group_ids = parse_last_response_body.included.map(&:id)
            expect(returned_group_ids).to contain_exactly(*groups.map(&:name))
          end
        end

        context 'when in standalone mode' do
          around(:all) { |e| run_in_standalone(&e) }

          it 'returns an empty array' do
            expect(parse_last_response_body.data).to be_empty
          end
        end
      end

      context 'when using group.all' do
        let(:groups) { demo_cluster.groups }

        before do
          groups_param = 'filter[group.all]=true'
          admin_headers
          get "files?#{base_params}&#{groups_param}"
        end

        context 'when in upstream mode' do
          it 'returns all the groups' do
            returned_group_ids = parse_last_response_body.included.map(&:id)
            expect(returned_group_ids).to contain_exactly(*groups.map(&:name))
          end
        end

        context 'when in standalone mode' do
          around(:all) { |e| run_in_standalone(&e) }

          it 'returns an empty array' do
            expect(parse_last_response_body.data).to be_empty
          end
        end
      end

      context 'when using cluster' do
        before do
          admin_headers
          get "files?#{base_params}&filter[cluster]=all"
        end

        context 'when in upstrea mode' do
          it 'can get the cluster' do
            returned_cluster_ids = parse_last_response_body.included.map(&:id)
            expect(returned_cluster_ids).to contain_exactly('default')
          end
        end

        context 'when in standalone mode' do
          around(:all) { |e| run_in_standalone(&e) }

          it 'returns an empty list' do
            expect(parse_last_response_body.data).to be_empty
          end
        end
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

  describe 'Show#GET' do
    it 'can get a template for a node' do
      template.save
      id = "#{template.id}.#{node.name}.nodes"
      admin_headers
      get "/files/#{id}"
      expect(last_response).to be_successful
    end
  end

  describe 'Create#POST' do
    let(:cluster_name) { demo_cluster.cluster.name }
    let(:file) { FileModel.new(context_model, template) }
    let(:rendered) do
      user_headers
      opts = {
        include_id: false,
        attributes: { template: template.payload },
        relationships: {
          context: context_model.tap do |ctx|
            ctx.id = (ctx.is_a?(ClusterRecord) ? 'default' : ctx.name)
          end
        }
      }
      post "/files", build_payload(file, **opts).to_json
      parse_last_response_body.data.attributes.payload
    end

    shared_examples 'can render' do
      it 'can render a temporary template' do
        expect(rendered).to eq(file.payload)
      end
    end

    context 'with a cluster context' do
      let(:context_model) do
        ClusterRecord.find(".#{cluster_name}").first
      end
      include_examples 'can render'
    end

    context 'with a group context' do
      let(:context_model) do
        GroupRecord.find("#{cluster_name}.#{demo_cluster.groups.first.name}")
                   .first
      end
      include_examples 'can render'
    end

    context 'with a node context' do
      let(:context_model) do
        NodeRecord.find("#{cluster_name}.#{demo_cluster.nodes.first.name}")
                  .first
      end

      include_examples 'can render'
    end
  end
end

