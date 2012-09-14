#
# Cookbook Name:: percona_server
# Recipe:: server
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


include_recipe "percona_server::client"
include_recipe "percona_server::filesystem"

case node[:platform]
when "centos","redhat","scientific"  
  yum_package "Percona-Server-server-55" do
    arch node[:kernel][:machine]
  end
  
  yum_package "perl-DBD-MySQL" do
    arch node[:kernel][:machine]
  end
when "ubuntu","debian"
  apt_package "percona-server-server-5.5" do
    options "-qq"
  end
  
  apt_package "libdbd-mysql-perl"
end

%w(/var/log/mysql /var/run/mysql).push(node[:percona_server][:datadir]).each do |dir|
  directory dir do
    mode 0755
    owner "mysql"
    group "mysql"
    recursive true
  end
end

cookbook_file "/etc/logrotate.d/mysql_slowqueries" do
  source "mysql_slowqueries-logrotate"
  mode 0644
  owner "root"
  group "root"
end
    
# We're only going to tune my.cnf for dedicated servers
# until we can get Ohai to report proper cpu/mem values
# for OpenVZ containers.
unless node[:virtualization][:role] == "guest"
  node.set[:percona_server][:host_type] = "dedicated"
  node.set[:percona_server][:memory] = (node[:memory][:total].to_i / 1000).to_i
      
  case node[:percona_server][:memory]
  when 1024..2047
    # 1GB
    node.set[:percona_server][:table_cache] = "128"
    node.set[:percona_server][:thread_cache] = "32"
    node.set[:percona_server][:innodb_buffer_pool_size] = "512M"
    node.set[:percona_server][:innodb_additional_mem_pool_size] = "2M"
  when 2048..4095
    # 2GB
    node.set[:percona_server][:table_cache] = "256"
    node.set[:percona_server][:thread_cache] = "64"
    node.set[:percona_server][:innodb_buffer_pool_size] = "1G"
    node.set[:percona_server][:innodb_additional_mem_pool_size] = "4M"
  when 4096..8191
    # 4GB
    node.set[:percona_server][:table_cache] = "512"
    node.set[:percona_server][:thread_cache] = "128"
    node.set[:percona_server][:innodb_buffer_pool_size] = "2G"
    node.set[:percona_server][:innodb_additional_mem_pool_size] = "10M"
  when 8192..16383
    # 8GB
    node.set[:percona_server][:table_cache] = "1024"
    node.set[:percona_server][:thread_cache] = "256"
    node.set[:percona_server][:innodb_buffer_pool_size] = "5G"
    node.set[:percona_server][:innodb_additional_mem_pool_size] = "20M"
  when 16384..32767
    # 16GB
    node.set[:percona_server][:table_cache] = "1024"
    node.set[:percona_server][:thread_cache] = "256"
    node.set[:percona_server][:innodb_buffer_pool_size] = "11G"
    node.set[:percona_server][:innodb_additional_mem_pool_size] = "20M"
  when node[:percona_server][:memory].to_i > 32768
    # 32GB
    node.set[:percona_server][:table_cache] = "1024"
    node.set[:percona_server][:thread_cache] = "256"
    node.set[:percona_server][:innodb_buffer_pool_size] = "25G"
    node.set[:percona_server][:innodb_additional_mem_pool_size] = "20M"
  end
else
  node.set[:percona_server][:host_type] = "virtual"
end
    
template "/etc/my.cnf" do
  source "my.cnf.erb"
  mode 0644
  owner "root"
  group "root"
  notifies :restart, "service[mysql]"
end
    
execute "mysql_install_db" do
  user "root"
  command "mysql_install_db --datadir=#{node[:percona_server][:datadir]}"
  creates "#{node[:percona_server][:datadir]}/mysql/user.frm"
  notifies :restart, "service[mysql]"
end
    
case node[:platform]
when "centos","redhat","scientific"
  service "mysql" do
    supports :restart => true, :status => true, :reload => true
    action [:enable, :start]
  end
when "ubuntu"
  template "/etc/init/mysql.conf" do
    source "upstart-mysql.conf.erb"
    mode 0644
    owner "root"
    group "root"
    backup false
  end
  
  service "mysql" do
    provider Chef::Provider::Service::Upstart
    supports :restart => true, :status => true, :reload => true
    action [:enable, :start]
  end
  
  link "/etc/init.d/mysql" do
    to "/lib/init/upstart-job"
  end
end
