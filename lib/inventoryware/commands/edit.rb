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
require 'inventoryware/commands/single_node_command'
require 'tty-editor'

module Inventoryware
  module Commands
    class Edit < SingleNodeCommand
      def action(node)
        # output to create the node's file if it doesn't yet exist
        node.save
        # maybe don't create unless saved? i.e. don't create the file above
        # instead save as closing
        TTY::Editor.open(node.location, command: :rvim)
      end
    end
  end
end
