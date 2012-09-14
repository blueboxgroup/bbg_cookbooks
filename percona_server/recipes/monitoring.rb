#
# Cookbook Name:: percona_server
# Recipe:: monitoring
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

case node[:platform]
when "centos","redhat","fedora","scientific"
  directory "/etc/mysql" do
    mode 0755
    owner "root"
    group "root"
  end
  
  execute "updatedb" do
    user "root"
  end
  
  node.set[:percona_server][:monitor_pw] = %x[/usr/bin/openssl rand 16 -base64 | tr -d \/ | tr -d \= | tr -d \+].chomp
  
  ruby_block "mysql-monitor-user" do
    block do
      system %Q(mysql -u root -e "GRANT SELECT ON mysql.* TO 'bluebox_monitor'@'localhost' IDENTIFIED BY '#{node[:percona_server][:monitor_pw]}';")
      system %Q(mysql -u root -e "GRANT SELECT ON mysql.* TO 'bluebox_monitor'@'127.0.0.1' IDENTIFIED BY '#{node[:percona_server][:monitor_pw]}';")
      system %Q(mysql -u root -e "GRANT SUPER,RELOAD,REPLICATION CLIENT,PROCESS,ALL ON *.* TO 'bluebox_monitor'@'localhost';")
    end
    not_if %Q(mysql -u root -e "SELECT User,Host FROM mysql.user;" | grep bluebox_monitor)
    notifies :create, "template[/etc/mysql/bluebox.cnf]", :immediately
    notifies :run, "execute[mysql-status-snmp]", :immediately
  end
  
  template "/etc/mysql/bluebox.cnf" do
    source "bluebox.cnf.erb"
    owner "root"
    group "root"
    mode 0600
    backup false
    action :nothing
  end
  
  execute "mysql-status-snmp" do
    user "root"
    command "/usr/blueboxgrp/snmp/client-scripts/mysql-status.pl -i"
    not_if "/bin/grep 'mysql-status.pl' /etc/snmp/snmpd.conf"
    action :nothing
  end
end
