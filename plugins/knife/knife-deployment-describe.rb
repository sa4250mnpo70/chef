# @file knife-deployment-describe.rb
#
# Project Clearwater - IMS in the Cloud
# Copyright (C) 2013  Metaswitch Networks Ltd
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation, either version 3 of the License, or (at your
# option) any later version, along with the "Special Exception" for use of
# the program along with SSL, set forth below. This program is distributed
# in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details. You should have received a copy of the GNU General Public
# License along with this program.  If not, see
# <http://www.gnu.org/licenses/>.
#
# The author can be reached by email at clearwater@metaswitch.com or by
# post at Metaswitch Networks Ltd, 100 Church St, Enfield EN2 6BQ, UK
#
# Special Exception
# Metaswitch Networks Ltd  grants you permission to copy, modify,
# propagate, and distribute a work formed by combining OpenSSL with The
# Software, or a work derivative of such a combination, even if such
# copying, modification, propagation, or distribution would otherwise
# violate the terms of the GPL. You must comply with the GPL in all
# respects for all of the code used other than OpenSSL.
# "OpenSSL" means OpenSSL toolkit software distributed by the OpenSSL
# Project and licensed under the OpenSSL Licenses, or a work based on such
# software and licensed under the OpenSSL Licenses.
# "OpenSSL Licenses" means the OpenSSL License and Original SSLeay License
# under which the OpenSSL Project distributes the OpenSSL toolkit software,
# as those licenses appear in the file LICENSE-OPENSSL.

require 'net/ssh'
require_relative 'knife-clearwater-utils'

module ClearwaterKnifePlugins
  class DeploymentDescribe < Chef::Knife
    include ClearwaterKnifePlugins::ClearwaterUtils

    banner "knife deployment describe -E ENV"

    deps do
      require 'chef'
      require 'fog'
      require 'nokogiri'
    end

    def run
      @ssh_key = File.join(attributes["keypair_dir"], "#{attributes["keypair"]}.pem")
      nodes = find_nodes.select { |n| n.roles.include? "clearwater-infrastructure" }
      nodes.each { |n| describe_node n }
    end
    
    def describe_node(node)
      hostname = node[:cloud][:public_hostname]
      puts "Packages on #{node.name}:"
      # puts "Roles: #{node.roles.join ","}"
      ssh_options = { keys: @ssh_key }
      Net::SSH.start(hostname, "ubuntu", ssh_options) do |ssh|
        node.roles.each do |role|
          if package_lookup.keys.include? role
            package_lookup[role].each do |package_name|
              raw_dkpg_output = ssh.exec! "dpkg -l #{package_name}"
              match_data = /#{package_name}\s+([0-9\.-]+)/.match raw_dkpg_output
              if match_data.nil?
                puts "No package version found"
              else
                puts "#{package_name} #{match_data[1]}"
              end
            end
          end
        end
      end
      puts "\n"
    end
    
    def package_lookup
      {
        "bono" => ["bono", "restund"],
        "clearwater-infrastructure" => ["clearwater-infrastructure"],
        "ellis" => ["ellis"],
        "homer" => ["homer"],
        "homestead" => ["homestead"],
        "sprout" => ["sprout", "sprout-libs"],
      }      
    end
  end
end