include_recipe "build-essential"

execute "remove-libtool-packages" do
  user "root"
  command "rpm -qa | grep libtool | rpm -e --nodeps $(xargs)"
  only_if "rpm -qa | grep libtool"
end

remote_file "/tmp/libtool-2.2.8.tar.gz" do
  owner "root"
  group "root"
  mode "0644"
  source "http://ftp.gnu.org/gnu/libtool/libtool-2.2.8.tar.gz"
  backup false
  action :create_if_missing
end

script "install-libtool" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
  tar xzvf libtool-2.2.8.tar.gz
  cd libtool-2.2.8
  ./configure
  make
  make install
  EOH
  not_if "/usr/bin/test -x /usr/local/bin/libtool"
end

cookbook_file "/etc/profile.d/libtool.sh" do
  owner "root"
  group "root"
  mode "0755"
  source "libtool.sh"
  backup false
  action :create_if_missing
end