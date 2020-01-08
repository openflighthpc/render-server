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

    def register_delegates(*methods, to:)
      methods.each do |method|
        self::Base.define_singleton_method(method) { raise NotImplementedError }
      end
      self::Upstream.eigen_class.delegate(*methods, to: to)
    end
  end
end

module NodeProxy
  include HasProxies

  register_delegates :where, :find, to: NodeRecord

  class Standalone
  end
end

