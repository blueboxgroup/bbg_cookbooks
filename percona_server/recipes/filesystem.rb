#
# Cookbook Name:: percona_server
# Recipe:: filesystem
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
when "centos","redhat","fedora","scientific","ubuntu"
  if node[:virtualization][:role] == "guest"
    log("This appears to be a VPS. Skipping percona_server::filesystem recipe.") { level :info }
  else
    include_recipe "xfs"
    
    # The string to parse. Force units to be in megabytes.
    # Array values:
    # 0: VG Name
    # 1: VSize (total)
    # 2: VFree (free)
    vg_info = `vgs --noheadings --units m --nosuffix --separator , -o vg_name,vg_size,vg_free`.chomp.lstrip.split(",")

    # The volume group name on this system. (eg: vg0)
    vg_name = vg_info[0]

    # Allocate all space for the LVM partition.  Keep in megabytes.
    data_size = vg_info[2].to_i
    data_units = "MB"

    # Let's assign the path to our /srv/data logical volume to this variable.
    data_path = "/dev/mapper/#{vg_name}-data"

    # Now we can create the new logical volume.
    execute "lvcreate" do
      user "root"
      command "lvcreate --name data --size #{data_size.to_s}#{data_units} #{vg_name}"
      # We won't run this command if the path below is already present.
      creates "#{data_path}"
    end
    
    # Write the file system to our new logical volume.
    execute "mkfs.xfs" do
      user "root"
      command "mkfs.xfs #{data_path}"
      not_if "xfs_info #{data_path}"
    end
    
    # Create the mount point.
    directory "#{node[:percona_server][:filesystem]}" do
      owner "root"
      group "root"
      mode "0755"
    end

    # Mount our new file system.
    mount "#{node[:percona_server][:filesystem]}" do
      device "#{data_path}"
      fstype "xfs"
      dump 0
      pass 1
      options "noatime,nodiratime"
      action [:mount, :enable]
    end
    
    # Set the proper MySQL data directory.
    node.set[:percona_server][:datadir] = node[:percona_server][:filesystem] + "/mysql"
  end
end
