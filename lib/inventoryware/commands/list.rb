#==============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file/package is part of Inventoryware.
#
# Inventoryware is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Inventoryware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on Inventoryware, please visit:
# https://github.com/openflighthpc/inventoryware
#==============================================================================
require 'inventoryware/command'
require 'inventoryware/config'

module Inventoryware
  module Commands
    class List < MultiNodeCommand
      def run
        files = if @options.group
                  find_nodes_in_groups(@options.group.split(','))
                else
                  Dir.glob(File.join(Config.yaml_dir, '*.yaml'))
                end
        file_names = get_file_names(files)

        unless file_names.empty?
          puts file_names.sort
        else
          return if @options.group
          puts "No asset files found within #{File.expand_path(Config.yaml_dir)}"
        end
      end

      private

      def get_file_names(files)
        files.map! do |file|
          File.basename(file, '.yaml')
        end
      end
    end
  end
end
