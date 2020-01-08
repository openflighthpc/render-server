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
    around(:all) do |example|
      NodeProxy.instance_variable_set(:@proxy_class, nil)
      ClimateControl.modify(remote_url: nil) { example.call }
      NodeProxy.instance_variable_set(:@proxy_class, nil)
    end

    it 'selects the standalone proxy' do
      expect(described_class.proxy_class).to eq(NodeProxy::Standalone)
    end
  end
end

