#!/usr/bin/env ruby
#==============================================================================
# Copyright (C) 2018 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces inventoryware.
#
# Alces inventoryware is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces inventoryware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on Alces inventoryware, please visit:
# https://github.com/alces-software/inventoryware
#==============================================================================

lib_dir = File.dirname(__FILE__)
ENV['BUNDLE_GEMFILE'] ||= File.join(lib_dir, '..', 'Gemfile')

require 'rubygems'
require 'bundler'

if ENV['INVWARE_DEBUG']
  Bundler.setup(:default, :development)
  require 'pry-byebug'
else
  Bundler.setup(:default)
end

require_relative 'cli'
require_relative 'lsblk_parser'
require 'erubis'
require 'lshw'
require 'tmpdir'
require 'yaml'
require 'zip'

def check_data_source?(data_source)
  !(File.file?(data_source) && File.extname(data_source) == ".zip")
end

TARGET_FILE = '/opt/inventory_tools/domain'

begin
  dir = Dir.mktmpdir('inv_ware_')
  tmp_lshw_xml = File.join(dir, 'lshw_xml')
  tmp_lsblk = File.join(dir, 'lsblk')

  # Parse arguments
  options = MainParser.parse(ARGV)

  data_source = options['data_source']
  hash = {}
  hash['Name'] = options['node']

  if check_data_source?(data_source)
    puts "Error with data source #{data_source}"\
         "- must be zip file"
    exit
  end

  Zip::File.open(data_source) do |zip_file|
    zip_file.each do |entry|
      puts "Extracting #{entry.name}"
    end
    zip_file.glob('lshw-xml.txt').first.extract(tmp_lshw_xml)
    zip_file.glob('lsblk-a-P.txt').first.extract(tmp_lsblk)
  end

  #TODO sort error conditions here
  f = File.open(tmp_lshw_xml)
  lshw = Lshw::XML(f)
  f.close

  hash['Hardware Type'] = lshw.product

  hash['System Serial Number'] = lshw.serial

  hash['Primary Group'] = options['pri_group']

  hash['Secondary Groups'] = options['sec_groups']

  hash['BIOS Version'] = lshw.firmware.first.version

  hash['CPUs'] = {}
  lshw.cpus.each do |cpu|
    hash['CPUs'][cpu.id] = {}
    hash['CPUs'][cpu.id]['Model'] = cpu.version
    hash['CPUs'][cpu.id]['Slot'] = cpu.slot
  end

  total_memory = 0
  lshw.memory_nodes.each do |mem|
    mem.banks.each do |bank|
      total_memory += bank.size
    end
  end

  hash['Total Memory'] = total_memory

  hash['Interfaces'] = {}
  lshw.all_network_interfaces.each do |net|
    hash['Interfaces'][net.logical_name] = {}
    hash['Interfaces'][net.logical_name]['Serial'] = net.mac
    hash['Interfaces'][net.logical_name]['Capacity'] = net.speed #DIVIDE THIS BY BITS N THAT:
  end

  lsblk = LsblkParser.new(tmp_lsblk)

  hash['Disks'] = {}
  lsblk.rows.each do |row|
    if row.type == 'disk'
      hash['Disks'][row.name] = {'Size'=>row.size}
    end
  end

  if !File.directory?(File.dirname(TARGET_FILE))
    puts "Directory #{File.dirname(TARGET_FILE)} not found - please create "\
      "before contining."
    exit
  end

  if options['template']
    template = File.read(options['template'])
    eruby = Erubis::Eruby.new(template)
    # overrides existing target file
    File.open(TARGET_FILE, 'w') { |file| file.write(eruby.result(:hash=>hash)) }
  else
    # make the node's name a key for the whole hash for pretty output
    yaml_hash = { hash['Name'] => hash }
    # appends to existing target file
    File.open(TARGET_FILE, 'a') { |file| file.write(yaml_hash.to_yaml) }
  end
ensure
  FileUtils.remove_entry dir
end