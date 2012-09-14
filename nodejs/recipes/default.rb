include_recipe "build-essential"

remote_file "/tmp/#{node["nodejs"]["node_version"]}" do
  source "http://nodejs.tchol.org/repocfg/el/#{node["nodejs"]["node_version"]}"
  action :create_if_missing
end

bash "install_nodejs" do
  cwd "/tmp"
  code <<-EOH
    yum localinstall -y --nogpgcheck #{node["nodejs"]["node_version"]}
    yum install -y nodejs-compat-symlinks npm
  EOH
  not_if "which node"
end
