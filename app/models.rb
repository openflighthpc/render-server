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

# Sinja has a weird "feature" (bug?) where it can not serialize Hash objects
# tl;dr Sinja thinks the Hash is the options to the serializer NOT the model
# Using a decorator design pattern for the models is a work around
class BaseHashieDashModel
  def self.inherited(klass)
    data_class = Class.new(Hashie::Dash) do
      include ActiveModel::Validations

      def self.method_added(m)
        parent.delegate(m, to: :data)
      end
    end

    klass.const_set('DataHash', data_class)
    klass.delegate(*(ActiveModel::Validations.instance_methods - Object.methods), to: :data)
  end

  attr_reader :data

  def initialize(*a)
    @data = self.class::DataHash.new(*a)
  end
end

class Template < BaseHashieDashModel
  def self.glob(name: '*', type: '*')
    paths = Dir.glob(path(name: name, type: type))
    paths.map do |p|
      matches = PATH_REGEX.match(p).named_captures
      new name: matches['name'],
          type: matches['type'],
          payload: File.read(p)
    end
  end

  def self.path(name:, type:)
    File.join(Figaro.env.templates_dir!, type, name)
  end
  PATH_REGEX = /#{path(name: '(?<name>.*)', type: '(?<type>.*)')}/

  def self.load_from_id(id)
    name, type = id.split('.', 2)
    new name: name,
        type: type,
        payload: File.read(path(type: type, name: name))
  rescue Errno::ENOENT
    nil
  end

  DataHash.class_exec do
    property :name
    property :payload,  default: ''
    property :type

    [:name, :type].each do |field|
      validates field, presence: true, format: {
        with: /\A[\w-]+\z/, message: 'must be alphanumeric and may contain - and _'
      }
    end

    def id
      "#{name}.#{type}"
    end

    def path
      self.class.parent.path(type: type, name: name)
    end

    def save
      validate!
      FileUtils.mkdir_p File.dirname(path)
      File.write(path, payload)
    end
  end
end

class FileModel
  class Builder
    attr_reader :id, :parts

    def initialize(id)
      @id = id
      @parts = id.split('.')
    end

    def resource
      if parts.length == 3 && parts.last == 'cluster'
        ClusterRecord.find(".#{Figaro.env.remote_cluster!}").first
      elsif parts.length == 4 && parts.last == 'nodes'
        NodeRecord.find("#{Figaro.env.remote_cluster!}.#{parts[-2]}").first
      elsif parts.length == 4 && parts.last == 'groups'
        GroupRecord.find("#{Figaro.env.remote_cluster!}.#{parts[-2]}").first
      end
    end

    def template
      Template.load_from_id("#{parts[0]}.#{parts[1]}")
    end
  end

  attr_reader :resource, :template

  def initialize(resource, template)
    @resource = resource
    @template = template
  end
end
