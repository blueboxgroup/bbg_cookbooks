#
# Cookbook Name:: rvm
# Recipe:: default
#
# Copyright 2010, Blue Box Group, LLC
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

include_recipe "build-essential"
include_recipe "git"

packages = case node[:platform]
  when "centos","redhat","fedora"
    %w{patch zlib-devel openssl-devel readline-devel libyaml-devel libffi-devel}.each do |pkg|
      yum_package pkg do
        arch node[:kernel][:machine]
      end
    end
  when "ubuntu","debian"
    %w{bison openssl libreadline5 libreadline-dev curl git-core zlib1g zlib1g-dev libssl-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev}.each do |pkg|
      package pkg do
        action :install
      end
    end
  end
end

bash "rvm-install" do
  cwd "/tmp"
  code <<-EOH
    /bin/bash < <(curl -s https://rvm.beginrescueend.com/install/rvm)
  EOH
  creates "/usr/local/rvm"
end

cookbook_file "/etc/profile.d/rvm.sh" do
  source "rvm.sh"
  path "/etc/profile.d/rvm.sh"
  owner "root"
  group "root"
  mode 0755
  backup false
end

cookbook_file "/etc/rvmrc" do
  source "rvmrc"
  path "/etc/rvmrc"
  owner "root"
  group "rvm"
  mode 0664
  backup false
end  
  
# Add RVM users to RVM group.
node[:rvm][:users].each do |user|
  # Make sure the user(s) exist first.
  # If a user was created during this Chef run, it will not exist in attributes.
  # Check /etc/passwd as well.
  if node[:etc][:passwd][user].nil? and ! %x[cat /etc/passwd].include?("\n#{user}") # Make sure the user(s) exist first.
    log("#{user} doesn't exist! Can't add this user to RVM group.") { level :error }
  else # Proceed.
    group "rvm" do
      members user
      append true
    end
  end
end

# Install our various rubies.
node[:rvm][:rubies].each do |ruby|
  log("Installing #{ruby} via RVM.") { level :info } # These installs take time so let's log the fact that we're starting the install.
  execute "rvm-install-#{ruby}" do
    command "/usr/local/rvm/bin/rvm install #{ruby}"
    creates "/usr/local/rvm/rubies/#{ruby}"
  end
end

# Set our default ruby.
execute "rvm-set-default" do
  command "/usr/local/rvm/bin/rvm --default #{node[:rvm][:default]}"
  not_if "/usr/local/rvm/bin/rvm list default | grep #{node[:rvm][:default]}"
end
