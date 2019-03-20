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
require 'inventoryware/commands/multi_node_command'
require 'inventoryware/exceptions'
require 'inventoryware/node'

module Inventoryware
  module Commands
    module Modifys
      class Other < MultiNodeCommand
        def run
          modification = @argv[0]

          unless modification.match(/=/)
            raise ArgumentError, <<-ERROR.chomp
Invalid modification - must contain an '='
            ERROR
          end
          field, value = modification.split('=')

          protected_fields = ['primary_group', 'secondary_groups']
          if protected_fields.include?(field)
            raise ArgumentError, <<-ERROR.chomp
Cannot modify '#{field}' this way
            ERROR
          end

          find_nodes("modification").each do |location|
            node = Node.new(location)
            type = Utils.get_new_asset_type if @options.create
            node.create_if_non_existent(type)
            if value
              node.data['mutable'][field] = value
            else
              node.data['mutable'].delete(field)
            end
            node.save
          end
        end
      end
    end
  end
end
