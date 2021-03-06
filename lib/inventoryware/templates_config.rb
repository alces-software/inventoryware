# =============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file is part of Flight Inventory.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Flight Inventory is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Flight Inventory. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Flight Inventory, please visit:
# https://github.com/openflighthpc/flight-inventory
# ==============================================================================

require 'inventoryware/config'
require 'inventoryware/exceptions'

module Inventoryware
  module TemplatesConfig
    class << self
      def find(format, type)
        format ||= 'default'
        if t = templates.dig(format, type) ||
               templates.dig(format, 'default')
          t
        else
          not_found_error(format, type)
        end
      end

      private
      def templates
        @templates ||= load
      end

      def load
        unless File.readable?(Config.templates_config_path)
          raise FileSysError, <<-ERROR.chomp
Template config at #{Config.templates_config_path} is inaccessible
        ERROR
        end
        template_data = {}
        Dir["#{Config.plugins_dir}/*"].each do |plugin|
          templates_config_file = File.join(plugin,'etc','templates.yml')
          if File.readable?(templates_config_file)
            template_data.merge!(load_template_config(templates_config_file))
          end
        end
        template_data.merge!(load_template_config(Config.templates_config_path))
      end

      def load_template_config(f)
        Utils.load_yaml(f).tap do |contents|
          unless contents.is_a?(Hash)
            raise ParseError, <<-ERROR.chomp
Template config at #{f} is in an incorrect format
            ERROR
          end
        end
      end

      def not_found_error(format, type)
        tag = format ? "Output format '#{format}' with a": 'A'
        raise ParseError, <<-ERROR.chomp
#{tag}sset type '#{type}' is not included in template config file
      ERROR
      end
    end
  end
end
