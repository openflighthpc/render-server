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

RSpec.describe '/groups' do
  describe 'Index#GET' do
    it 'can proxy requests to nodeattr-server' do
      admin_headers
      get '/groups'
      groups = parse_last_response_body.data.map(&:id)
      expect(groups).to contain_exactly(*DemoCluster.new.groups.map(&:name))
    end
  end

  describe 'Show#GET' do
    it 'can proxy requests to nodeattr-server' do
      group = DemoCluster.new.groups.first
      admin_headers
      get "/groups/#{group.name}"
      expect(parse_last_response_body.data.id).to eq(group.name)
    end

    it 'returns 404 when the proxy fails' do
      admin_headers
      get "/groups/missing"
      expect(last_response).to be_not_found
    end
  end

  context 'when in standalone mode' do
    around(:all) { |e| run_in_standalone(&e) }

    it 'returns an empty list when indexing groups' do
      admin_headers
      get '/groups'
      expect(parse_last_response_body.data).to be_empty
    end

    it 'returns not found when getting a group' do
      group = DemoCluster.new.groups.first
      admin_headers
      get "/groups/#{group.name}"
      expect(last_response).to be_not_found
    end
  end
end

