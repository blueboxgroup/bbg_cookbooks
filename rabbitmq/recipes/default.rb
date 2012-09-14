include_recipe "erlang"

case node[:platform]
when "centos","redhat","scientific"
  yum_package "rabbitmq-server"
  
  template "/etc/sysconfig/rabbitmq" do
    owner "root"
    group "root"
    mode 0644
    source "rabbitmq-sysconfig.erb"
  end

  service "rabbitmq-server" do
    supports :status => true, :restart => true, :reload => true
    action [ :enable, :start ]
  end
end
