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

require 'sinja'
require 'sinja/method_override'
require 'hashie'

use Sinja::MethodOverride
register Sinja

configure_jsonapi do |c|
  c.validation_exceptions << ActiveModel::ValidationError

  c.validation_formatter = ->(e) do
    e.model.errors.messages
    # relations = e.model.relations.keys.map(&:to_sym)
    # e.model.errors.messages.map do |src, msg|
    #   relations.include?(src) ? [src, msg, 'relationships'] : [src, msg]
    # end
  end

  # # Resource roles
  # c.default_roles = {
  #   index: [:user, :admin],
  #   show: [:user, :admin],
  #   create: :admin,
  #   update: :admin,
  #   destroy: :admin
  # }

  # # To-one relationship roles
  # c.default_has_one_roles = {
  #   pluck: [:user, :admin],
  #   prune: :admin,
  #   graft: :admin
  # }

  # # To-many relationship roles
  # c.default_has_many_roles = {
  #   fetch: [:user, :admin],
  #   clear: :admin,
  #   replace: :admin,
  #   merge: :admin,
  #   subtract: :admin
  # }
end

helpers do
  def serialize_model(model, options = {})
    JSONAPI::Serializer.serialize(model, options)
  end

  # def jwt_token
  #   if match = BEARER_REGEX.match(env['HTTP_AUTHORIZATION'] || '')
  #     match.captures.first
  #   else
  #     ''
  #   end
  # end

  # def role
  #   token = Token.from_jwt(jwt_token)
  #   if token.admin && token.valid
  #     :admin
  #   elsif token.valid
  #     :user
  #   else
  #     :unknown
  #   end
  # end
end

PKRE_REGEX = /[\w-]+/
resource :nodes, pkre: PKRE_REGEX do
  helpers do
    def find(id)
      NodeProxy.find("#{Figaro.env.remote_cluster!}.#{id}").first
    rescue JsonApiClient::Errors::NotFound
      nil
    end
  end

  index do
    NodeProxy.where(cluster_id: ".#{Figaro.env.remote_cluster!}").all
  end

  show
end

resource :groups, pkre: PKRE_REGEX do
  helpers do
    def find(id)
      GroupRecord.find("#{Figaro.env.remote_cluster!}.#{id}").first
    rescue JsonApiClient::Errors::NotFound
      nil
    end
  end

  index do
    GroupRecord.where(cluster_id: ".#{Figaro.env.remote_cluster!}").all
  end

  show
end

resource :clusters, pkre: /default/ do
  helpers do
    def default_cluster
      ClusterProxy.find(".#{Figaro.env.remote_cluster!}").first
    end

    def find(_)
      default_cluster
    end
  end

  index { [default_cluster] }

  show
end

resource :templates, pkre: /[\.\w-]+/ do
  helpers do
    def find(id)
      Template.load_from_id(id)
    end
  end

  index do
    Template.glob
  end

  show

  create do |attr|
    template = Template.new(**attr).tap(&:save)
    next template.id, template
  end

  update do |attr|
    resource.payload = attr[:payload] if attr[:payload]
    resource.save
    resource
  end

  destroy do
    FileUtils.rm_f resource.path
  end
end

FilesSelector = Struct.new(:fields) do
  def files
    contexts.map { |c| templates.map { |t| FileModel.new(c, t) } }.flatten
  end

  def templates
    if ids = fields[:ids]
      ids.split(',').map { |id| Template.load_from_id(id) }.reject(&:nil?)
    else
      []
    end
  end

  def contexts
    [*nodes, *groups, *clusters].reject(&:nil?)
  end

  private

  def nodes
    if fields[:'node.all']
      NodeProxy.where(cluster_id: ".#{Figaro.env.remote_cluster!}").to_a
    else
      accum = []
      if ids = fields[:'node.ids']
        accum << ids.split(',').map do |id|
          begin
            NodeProxy.find("#{Figaro.env.remote_cluster!}.#{id}")
          rescue JsonApiClient::Errors::NotFound
            []
          end.first
        end
      end
      if ids = fields[:'node.group_ids']
        accum << ids.split(',').map do |id|
          begin
            GroupRecord.includes(:nodes)
                       .find("#{Figaro.env.remote_cluster!}.#{id}")
                       .first
                       .nodes
          rescue JsonApiClient::Errors::NotFound
            []
          end
        end
      end
      accum.flatten.uniq(&:id)
    end
  end

  def groups
    if fields[:'group.all']
      GroupRecord.where(cluster_id: ".#{Figaro.env.remote_cluster!}").to_a
    elsif ids = fields[:'group.ids']
      ids.split(',').map do |id|
        begin
          GroupRecord.find("#{Figaro.env.remote_cluster!}.#{id}")
        rescue JsonApiClient::Errors::NotFound
          []
        end.first
      end
    end
  end

  def clusters
    fields[:cluster] ? [ClusterProxy.find(".#{Figaro.env.remote_cluster!}").first] : []
  end
end

resource :files, pkre: /[.\w-]+/ do
  helpers do
    def find(id)
      FileModel.build(id)
    end

    def filter(_, **fields)
      FilesSelector.new(fields).files
    end
  end

  filter_keys = [
    :ids,
    :'node.ids',
    :'node.group_ids',
    :'node.all',
    :'group.ids',
    :'group.all',
    :cluster
  ]
  index(filter_by: filter_keys) { [] }

  show
end

