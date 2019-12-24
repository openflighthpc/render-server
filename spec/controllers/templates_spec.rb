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

RSpec.describe '/templates' do
  describe 'Show#GET' do
    let(:template_payload) { 'Initial Template Content' }
    let(:template) do
      Template.new  type: 'some-template_type',
                    name: 'test_template-name',
                    payload: template_payload
    end

    it 'returns 404 if the template is missing' do
      admin_headers
      get '/templates/missing.type'
      expect(last_response).to be_not_found
    end

    it 'can retreive a template' do
      template.save
      admin_headers
      get "/templates/#{template.id}"
      expect(parse_last_response_body.data.attributes.payload).to eq(template_payload)
    end
  end
end

