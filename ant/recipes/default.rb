include_recipe "build-essential"
include_recipe "openjdk"

remote_file "/tmp/apache-ant-1.8.2-bin.tar.gz" do
  owner "root"
  group "root"
  source "http://www.fightrice.com/mirrors/apache/ant/binaries/apache-ant-1.8.2-bin.tar.gz"
  mode "0644"
  backup false
  action :create_if_missing
end

script "install-ant" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
  tar xzvf apache-ant-1.8.2-bin.tar.gz
  mv apache-ant-1.8.2/ /opt/ant
  EOH
  not_if "/usr/bin/test -d /opt/ant"
end

cookbook_file "/etc/profile.d/ant.sh" do
  owner "root"
  group "root"
  mode "0755"
  source "ant.sh"
  backup false
end

script "ant-add-paths" do
  interpreter "bash"
  user "root"
  code <<-EOH
  export ANT_HOME=/opt/ant
  export PATH=/opt/ant/bin:$PATH
  EOH
end
