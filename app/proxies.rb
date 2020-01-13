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

module HasProxies
  extend ActiveSupport::Concern

  included do
    class self::Base
    end

    class self::Upstream < self::Base
      def self.eigen_class
        class << self; return self; end
      end
    end

    class self::Standalone < self::Base
    end
  end

  class_methods do
    delegate_missing_to :proxy_class

    def proxy_class
      @proxy_class ||= Figaro.env.remote_url ? self::Upstream : self::Standalone
    end

    def register_upstream_delegates(*methods, to:)
      define_abstract_methods(*methods)
      self::Upstream.eigen_class.delegate(*methods, to: to)
    end

    def register_standalone_methods(*methods, &block)
      define_abstract_methods(*methods)
      methods.each do |method|
        self::Standalone.define_singleton_method(method) do |*a, &b|
          block.call(*a, &b)
        end
      end
    end

    private

    def define_abstract_methods(*methods)
      methods.each do |method|
        next if self::Base.respond_to?(method)
        self::Base.define_singleton_method(method) { |*_| raise NotImplementedError }
      end
    end
  end
end

class EmptyRequestProxy
  def all
    []
  end

  def to_a
    []
  end
end

class Topology < Hashie::Trash
  class Cache
    class << self
      delegate_missing_to :instance

      def instance
        @instance = parent.new(YAML.load(File.read(Figaro.env.topology_config!), symbolize_names: true))
      end
    end
  end

  include Hashie::Extensions::IgnoreUndeclared

  property :nodes, transform_with: ->(node_hashes) do
    node_hashes.map do |name, params|
      NodeRecord.new(name: name, params: params)
    end
  end

  def find_node(name)
    @find_node ||= {}
    @find_node[name] ||= nodes.find { |n| n.name == name }
  end
end

# NOTE: Ensure the topology file exists in standalone mode
Topology::Cache.instance unless Figaro.env.remote_url

module NodeProxy
  include HasProxies

  register_upstream_delegates :where, :find, to: NodeRecord
  register_standalone_methods(:where) do |cluster_id:|
    # NOTE: There is no cluster in standalone mode. The cluster_id is only
    # accepted so it maintains the interface with Upstream
    Topology::Cache.nodes
  end

  # Find returns a single element array because that is how NodeRecord.find works
  register_standalone_methods(:find) do |id|
    # The ID contains the cluster_id, which is ignored in standalone mode
    _, name = id.split('.', 2)
    node = Topology::Cache.find_node(name) || raise(JsonApiClient::Errors::NotFound.new('Standalone Mode'))
    JsonApiClient::ResultSet.new [node]
  end
end

module GroupProxy
  include HasProxies

  register_upstream_delegates(:find, :where, :includes, to: GroupRecord)
  register_standalone_methods(:find) { [] }
  register_standalone_methods(:where) { EmptyRequestProxy.new }
  register_standalone_methods(:includes) { self }
end

module ClusterProxy
  include HasProxies

  register_upstream_delegates :find, to: ClusterRecord
  register_standalone_methods(:find) { [] }
end

