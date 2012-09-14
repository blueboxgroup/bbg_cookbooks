# Cookbook Name:: git
# Recipe:: default
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

memcached_package = "memcached"

case node[:platform]
when "centos","redhat","fedora","scientific"
  yum_package memcached_package do
    arch node[:kernel][:machine]
  end
when "debian","ubuntu"
  apt_package memcached_package
end

template "memcached" do
  case node[:platform]
  when "centos","redhat","fedora","scientific"
    path "/etc/sysconfig/memcached"
    source "memcached.erb"
  when "debian","ubuntu"
    path "/etc/memcached.conf"
    source "memcached.conf.erb"
  end
  backup false
  notifies :restart, "service[memcached]", :immediately
end

service "memcached" do
  supports :start => true, :stop => true, :restart => true
  action [ :enable, :start ]
end
