# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2020-present Alces Flight Ltd.
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

RSpec.describe Template do
  let(:valid_name) { 'some_valid-name.part.ext' }
  let(:invalid_name) { '%name%' }
  subject { Template.new(name: name, saved: saved) }

  context 'with a valid name and saved' do
    let(:name) { valid_name }
    let(:saved) { true }

    it 'is valid' do
      expect(subject).to be_valid
    end
  end

  context 'when saved without a name' do
    let(:name) { nil }
    let(:saved) { true }

    it 'is not valid' do
      expect(subject).not_to be_valid
    end
  end

  context 'with a valid name but without saved' do
    let(:name) { valid_name }
    let(:saved) { false }

    it 'is valid' do
      expect(subject).to be_valid
    end
  end

  context 'without a name nor saved' do
    let(:name) { nil }
    let(:saved) { false }

    it 'is valid' do
      expect(subject).to be_valid
    end
  end

  context 'when saved with an invalid name' do
    let(:name) { invalid_name }
    let(:saved) { true }

    it 'is invalid' do
      expect(subject).not_to be_valid
    end
  end

  context 'with an invalid name without saved' do
    let(:name) { invalid_name }
    let(:saved) { false }

    it 'is invalid' do
      expect(subject).not_to be_valid
    end
  end

  context 'with a blank name with saved' do
    let(:name) { '' }
    let(:saved) { true }

    it 'is invalid' do
      expect(subject).not_to be_valid
    end
  end

  context 'with a blank name without saved' do
    let(:name) { '' }
    let(:saved) { false }

    it 'is valid' do
      expect(subject).to be_valid
    end
  end
end

