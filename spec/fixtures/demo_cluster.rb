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

class DemoCluster
  def cluster
    @cluster ||= ClusterRecord.new(
      name: Figaro.env.remote_cluster,
      level_params: {
        platform: 'demo',
        key: 'cluster',
        cluster: Figaro.env.remote_cluster
      }
    )
  end

  def nodes
    @nodes ||= (1..10).map do |idx|
      name = "node#{idx}"
      NodeRecord.new(
        name: name,
        level_params: {
          key: name,
          ip: "10.10.0.#{idx}"
        },
        relationships: { cluster: cluster }
      )
    end
  end

  def groups
    @groups ||= begin
      g = []

      # NOTE: The odds/evens only look reversed because node01 is at index 0
      evens = nodes.each_with_index.reject { |_, i| i.even? }.map { |n, _| n }
      odds = nodes.each_with_index.select { |_, i| i.even? }.map { |n, _| n }

      g << GroupRecord.new(
        name: 'even',
        level_params: {
          key: 'even',
          even: true
        },
        relationships: { cluster: cluster, nodes: evens }
      )

      g << GroupRecord.new(
        name: 'odd',
        level_params: {
          key: 'odd',
          even: false
        },
        relationships: { cluster: cluster, nodes: odds }
      )

      g << GroupRecord.new(
        name: 'subnet',
        level_params: {
          key: 'subnet',
          subnet: '10.10.0.0/24'
        },
        relationships: { cluster: cluster, nodes: nodes }
      )

      g
    end
  end
end
