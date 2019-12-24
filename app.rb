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
  c.validation_formatter = ->(e) do
    relations = e.model.relations.keys.map(&:to_sym)
    e.model.errors.messages.map do |src, msg|
      relations.include?(src) ? [src, msg, 'relationships'] : [src, msg]
    end
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
      NodeRecord.find("#{Figaro.env.remote_cluster!}.#{id}").first
    rescue JsonApiClient::Errors::NotFound
      nil
    end
  end

  index do
    NodeRecord.where(cluster_id: ".#{Figaro.env.remote_cluster!}").all
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
      ClusterRecord.find(".#{Figaro.env.remote_cluster!}").first
    end

    def find(_)
      default_cluster
    end
  end

  index { [default_cluster] }

  show
end

resource :templates, pkre: /#{PKRE_REGEX}\.#{PKRE_REGEX}/ do
  helpers do
    def find(id)
      Template.load_from_id(id)
    end
  end

  show
end

