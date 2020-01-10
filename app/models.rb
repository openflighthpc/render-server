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
  def self.glob(name: '*')
    paths = Dir.glob(path(name: name))
    paths.map do |p|
      new(name: File.basename(p), payload: File.read(p))
    end
  end

  def self.path(name:)
    File.join(Figaro.env.templates_dir!, "#{name}")
  end

  def self.load_from_id(id)
    new name: id,
        saved: true,
        payload: File.read(path(name: id))
  rescue Errno::ENOENT
    nil
  end

  DataHash.class_exec do
    property :name
    property :saved
    property :payload,  default: ''

    validates :name, presence: true, format: {
      with: /\A[\.\w-]+\z/, message: 'must be alphanumeric and may contain: -_.'
    }

    def id
      name
    end

    def path
      self.class.parent.path(name: name)
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
    attr_reader :id, :scope, :name, :template_id

    ID_REGEX = /\A(?<template>.*)\.(?<name>[^\.]*)\.(?<scope>[^\.]*)\Z/

    def initialize(id)
      @id = id
      if ID_REGEX.match?(id)
        matches = ID_REGEX.match(id)
        @scope = matches.named_captures['scope']
        @name = matches.named_captures['name']
        @template_id = matches.named_captures['template']
      end
    end

    def build
      args = [context, template].reject(&:nil?)
      self.class.parent.new(*args) if args.length == 2
    end

    def context
      case scope
      when 'nodes'
        NodeRecord.find("#{Figaro.env.remote_cluster!}.#{name}").first
      when 'groups'
        GroupRecord.find("#{Figaro.env.remote_cluster!}.#{name}").first
      when 'clusters'
        ClusterRecord.find(".#{Figaro.env.remote_cluster!}").first
      end
    end

    def template
      Template.load_from_id(template_id)
    end
  end

  def self.build(id)
    Builder.new(id).build
  end

  attr_reader :context, :template

  def initialize(context, template)
    @context = context
    @template = template
  end

  def id
    suffix =  case context
              when NodeRecord
                "#{context.name}.nodes"
              when GroupRecord
                "#{context.name}.groups"
              when ClusterRecord
                'default.clusters'
              else
                raise 'An unexpected error has occurred'
              end
    "#{template.id}.#{suffix}"
  end

  def payload
    context.params.reduce(template.payload) do |memo, (key, value)|
      memo.gsub("%#{key}%", value.to_s)
    end
  end
end

