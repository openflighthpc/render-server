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

RSpec.describe FileModel::Builder do
  let(:demo_cluster) { DemoCluster.new(ids: true) }
  let(:template) { Template.new(name: 'template-name', type: 'template-type') }
  let(:id) do
    suffix = case resource
             when ClusterRecord
               'cluster'
             when GroupRecord
               "#{resource.name}.groups"
             when NodeRecord
               "#{resource.name}.nodes"
             end
    "#{template.name}.#{template.type}.#{suffix}"
  end
  let(:resource) { raise 'The resource has not been defined' }

  subject { described_class.new(id) }

  shared_examples 'file model builder methods' do
    describe '#context' do
      it { expect(subject.context.id).to eq(resource.id) }
    end

    describe '#template' do
      it { expect(subject.template.path).to eq(template.path) }
    end

    describe '#build' do
      it { expect(subject.build).to be_a(described_class.parent) }
    end
  end

  context 'with an existing template' do
    before { template.save }

    context 'with cluster resource' do
      let(:resource) { ClusterRecord.find(demo_cluster.cluster.id).first }

      include_examples 'file model builder methods'
    end

    context 'with node resource' do
      let(:resource) { NodeRecord.find(demo_cluster.nodes.first.id).first }

      include_examples 'file model builder methods'
    end

    context 'with group resource' do
      let(:resource) {GroupRecord.find(demo_cluster.groups.last.id).first }

      include_examples 'file model builder methods'
    end
  end

  describe '#build' do
    let(:id) { '' }

    it 'returns nil when the template is missing' do
      allow(subject).to receive(:template).and_return(nil)
      allow(subject).to receive(:context).and_return(demo_cluster.cluster)
      expect(subject.build).to be_nil
    end

    it 'returns nil when the context is missing' do
      allow(subject).to receive(:template).and_return(template)
      allow(subject).to receive(:context).and_return(nil)
      expect(subject.build).to be_nil
    end
  end
end

