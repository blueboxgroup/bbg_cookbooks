#
# Cookbook Name:: percona_server
# Recipe:: client
#
# Copyright 2011, Blue Box Group, LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "percona_server::repository"

case node[:platform]
when "centos","redhat","scientific"
  %w(MySQL-shared-compat MySQL-client-community MySQL-devel-community).each do |pkg|
    yum_package pkg do
      action :remove
    end
  end
    
  %w(Percona-Server-client-55 Percona-Server-devel-55 Percona-Server-shared-compat).each do |pkg|
    yum_package pkg do
      arch node[:kernel][:machine]
    end
  end
when "ubuntu","debian"
  %w(percona-server-client-5.5 libmysqlclient-dev percona-server-common-5.5).each do |pkg|
    apt_package pkg
  end
end
