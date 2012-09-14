#
# Cookbook Name:: percona_server
# Recipe:: repository
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
when "centos","redhat","scientific"
  # Package provides the repository GPG key.
  execute "percona-release" do
    command "rpm -U http://www.percona.com/downloads/percona-release/percona-release-0.0-1.x86_64.rpm"
    not_if "rpm -q percona-release"
  end
  
  # Overwrite repository configuration to use '5' or '6' instead of
  # '5.7' or '6.1' since Percona is usually a bit behind releases.
  template "/etc/yum.repos.d/Percona.repo" do
    owner "root"
    group "root"
    mode "0644"
    source "Percona.repo.erb"
  end
when "ubuntu","debian"
  template "/etc/apt/sources.list.d/percona.list" do
    source "apt-sources-percona.list.erb"
    mode 0644
    owner "root"
    group "root"
  end
  
  script "install-percona-repo-key" do
    user "root"
    interpreter "bash"
    code <<-EOH
      gpg --keyserver hkp://keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
      gpg -a --export CD2EFD2A | apt-key add -
      apt-get update
    EOH
  end
end
