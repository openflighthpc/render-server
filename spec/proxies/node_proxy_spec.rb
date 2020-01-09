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

RSpec.describe NodeProxy do
  context 'when in upstream mode' do
    # NOOP: The default spec environment is in upstream mode

    it 'selects the upstream proxy' do
      expect(described_class.proxy_class).to eq(NodeProxy::Upstream)
    end

    [:where, :find].each do |method|
      describe "##{method}" do
        let(:inputs) { ['some', 'random', 'array', 'of', 'inputs'] }

        it 'is delegated to NodeRecord' do
          expect(NodeRecord).to receive(method).with(*inputs)
          NodeProxy.send(method, *inputs)
        end
      end
    end
  end

  context 'when in standalone mode' do
    around(:all) { |e| run_in_standalone(&e) }

    it 'selects the standalone proxy' do
      expect(described_class.proxy_class).to eq(NodeProxy::Standalone)
    end

    describe '#where' do
      it 'errors when called with an unrecognised key' do
        expect do
          described_class.where(cluster_id: '', some_random_key: true)
        end.to raise_error(ArgumentError)
      end

      it 'returns all the topology nodes' do
        nodes = described_class.where(cluster_id: '')
        expect(nodes.map(&:name)).to contain_exactly(*topology.nodes.keys)
      end

      it 'returns an array of NodeRecord' do
        described_class.where(cluster_id: '').each do |node|
          expect(node).to be_a(NodeRecord)
        end
      end
    end

    describe '#find' do
      it 'returns a single element NodeRecord array' do
        name = topology.nodes.keys.last
        nodes = described_class.find("noop-cluster.#{name}")
        expect(nodes.length).to be(1)
        expect(nodes.first).to be_a(NodeRecord)
        expect(nodes.first.name).to eq(name)
      end
    end
  end
end

