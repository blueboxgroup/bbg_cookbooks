include_recipe "build-essential"

case node[:platform]
when "redhat","centos","fedora","scientific"
  %w{boost boost-devel boost-doc}.each do |pkg|
    package pkg do
      action :purge
    end
  end
when "debian","ubuntu"
  %w{libboost-all-dev}.each do |pkg|
    package pkg do
      action :purge
    end
  end
end

remote_file "/tmp/#{node[:boost][:file]}" do
  source node[:boost][:source] + node[:boost][:file]
  mode "0644"
  action :create_if_missing
end

script "install-boost" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
  tar xzvf #{node[:boost][:file]}
  cd #{node[:boost][:build_dir]}
  ./bootstrap.sh && ./bjam install
  EOH
  not_if "/sbin/ldconfig -v | grep boost"
end

execute "ldconfig" do
  user "root"
  command "/sbin/ldconfig"
  action :nothing
end

cookbook_file "/etc/ld.so.conf.d/boost.conf" do
  owner "root"
  group "root"
  mode "0644"
  source "boost.conf"
  backup false
  notifies :run, resources(:execute => "ldconfig"), :immediately
end
