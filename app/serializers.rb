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

class NodeRecordSerializer
  include JSONAPI::Serializer

  def id
    object.name
  end

  def type
    'nodes'
  end

  attributes :name
end

class GroupRecordSerializer
  include JSONAPI::Serializer

  def id
    object.name
  end

  def type
    'groups'
  end

  attributes :name
end

class ClusterRecordSerializer
  include JSONAPI::Serializer

  # NOTE: The API only supports a single cluster called "default"
  # The actual remote cluster maybe called a different name
  def id
    'default'
  end

  def type
    'clusters'
  end

  attribute :name
end


class TemplateSerializer
  include JSONAPI::Serializer

  attribute :name
  attribute :payload
end

class FileModelSerializer
  include JSONAPI::Serializer

  def type
    'files'
  end

  has_one :context
  has_one :template

  attribute :payload
end

