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
  describe 'Index#GET' do
    it 'returns the templates' do
      temp1 = Template.new  name: 'template1',
                            payload: ''
      temp2 = Template.new  name: 'template2.part.ext',
                            payload: ''
      temp1.save
      temp2.save
      admin_headers
      get '/templates'
      expect(parse_last_response_body.data.map(&:id)).to \
        contain_exactly(temp1.id, temp2.id)
    end
  end

  ['test_template-name', 'name.part.ext'].each do |name|
    describe "Show#GET #{name}" do
      let(:template_payload) { 'Initial Template Content' }
      let(:template) do
        Template.new  name: name,
                      payload: template_payload
      end

      it 'returns 404 if the template is missing' do
        admin_headers
        get '/templates/missing'
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

  describe 'Create#POST' do
    let(:template) { Template.new name: 'test_name-1', payload: 'some-content' }
    let(:payload) do
      build_payload template,
                    attributes: { name: template.name, payload: template.payload },
                    include_id: false
    end

    it 'creates a new template' do
      admin_headers
      post '/templates', payload.to_json
      expect(File.read(template.path)).to eq(template.payload)
    end

    it 'errors if the name is invalid' do
      attributes = {
        name: template.name,
        payload: template.payload
      }.tap { |a| a[:name] = 'bad%%value' }
      payload = build_payload template, attributes: attributes, include_id: false
      admin_headers
      post '/templates', payload.to_json
      expect(last_response).to be_unprocessable
    end

    it 'errors if the template already exists' do
      template.save
      admin_headers
      post '/templates', payload.to_json
      expect(last_response.status).to be(409)
    end
  end

  describe 'Update#PATCH' do
    let(:template) { Template.new name: 'test_name-for_update', payload: 'original' }

    it 'errors if missing' do
      payload = build_payload template
      admin_headers
      patch "/templates/#{template.id}", payload.to_json
      expect(last_response).to be_not_found
    end

    it 'can update the template content' do
      template.save
      new_content = 'I am the new template content'
      payload = build_payload template, attributes: { payload: new_content }
      admin_headers
      patch "/templates/#{template.id}", payload.to_json
      updated_template = Template.load_from_id(template.id)
      expect(updated_template.payload).to eq(new_content)
    end

    it 'can preform a noop' do
      template.save
      admin_headers
      patch "/templates/#{template.id}", build_payload(template).to_json
      expect(last_response).to be_successful
      new_template = Template.load_from_id(template.id)
      expect(new_template.payload).to eq(template.payload)
    end
  end

  describe 'Destroy#DELETE' do
    let(:template) { Template.new name: 'test_name-for_destroy', payload: 'original' }

    it 'removes the tempalte' do
      template.save
      admin_headers
      delete "/templates/#{template.id}"
      expect(File.exists? template.path).to be false
    end
  end
end

