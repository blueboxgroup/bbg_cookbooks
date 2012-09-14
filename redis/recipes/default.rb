include_recipe "build-essential"
include_recipe "blocks_firewall"

user "redis" do
  comment "Redis Administrator"
  system true
  shell "/sbin/nologin"
end

directory "#{node[:redis][:dir]}" do
  owner "redis"
  #group "redis" # See issue below.
  mode "0755"
end

# Create the rest of the directories.
node[:redis][:dirs].each do |dir|
  unless File.directory? node[:redis][:dir] + "/" + dir
    directory node[:redis][:dir] + "/" + dir do
      owner "redis"
      #group "redis" # See issue below.
      mode "0755"
      recursive true
    end
  end
end
  
# Unfortunately we're hitting a bug in Chef that they've yet to resolve. This means we can't use the 'group' attribute to set proper ownership
# on the directories we created above. We'll have to use this until the resolve the issue.
# Bug report: http://tickets.opscode.com/browse/CHEF-1699
execute "chown-redis-dir" do
  user "root"
  command "chown redis:redis #{node[:redis][:dir]}"
end
  
node[:redis][:dirs].each do |dir|
  execute "chown-redis-#{dir}" do
    user "root"
    command "chown redis:redis #{node[:redis][:dir]}/#{dir}"
  end
end

remote_file "/tmp/redis-#{node[:redis][:version]}.tar.gz" do
  source "http://redis.googlecode.com/files/redis-#{node[:redis][:version]}.tar.gz"
  backup false
  action :create_if_missing
  not_if "#{node[:redis][:dir]}/bin/redis-server --version | grep #{node[:redis][:version]}" # Don't download if we already have this version installed.
end

bash "compile-redis" do
  cwd "/tmp"
  code <<-EOH
    tar zxf redis-#{node[:redis][:version]}.tar.gz
    cd redis-#{node[:redis][:version]} && make
  EOH
  not_if "#{node[:redis][:dir]}/bin/redis-server --version | grep #{node[:redis][:version]}" # Don't compile if we already have this version installed.
end

ruby_block "installing-binaries" do
  block do
    node[:redis][:binaries].each do |bin|
      if File.exist?(node[:redis][:dir] + "/bin/" + bin) # If destination binary exists, then we need to compare our fresh compile w/ what's there.
        unless File.read("/tmp/redis-#{node[:redis][:version]}/src/#{bin}") == File.read("#{node[:redis][:dir]}/bin/#{bin}") # Unless the files are the same...
          system("cp -a /tmp/redis-#{node[:redis][:version]}/src/#{bin} #{node[:redis][:dir]}/bin/#{bin}") # Copy them over.
        end
      else 
        system("cp -a /tmp/redis-#{node[:redis][:version]}/src/#{bin} #{node[:redis][:dir]}/bin/#{bin}") # These were safe to move w/o comparing.
      end
    end
  end
end 

# Create profile.d script to add redis directory to $PATH.
template "/etc/profile.d/redis.sh" do
  owner "root"
  group "root"
  source "redis.sh.erb"
  mode "0755"
  backup false
end

#  setup and start init per platform
case node[:platform]
when "centos","redhat","scientific"
  template "/etc/init.d/redis-server" do
    owner "root"
    group "root"
    source "redis-init.erb"
    mode "0755"
    backup false
  end
  
  service "redis-server" do
    supports :start => true, :stop => true, :restart => true
    action :enable
  end
when "ubuntu"
  template "/etc/init/redis-server.conf" do
    owner "root"
    group "root"
    source "redis-upstart.conf.erb"
    mode "0755"
    backup false
  end
  
  link "/etc/init.d/redis-server" do
    to "/lib/init/upstart-job"
  end
  
  service "redis-server" do
    provider Chef::Provider::Service::Upstart
    supports :status => true, :restart => true, :reload => true
    action [ :enable, :start ]
  end
end

# Create configuration file.
template "#{node[:redis][:dir]}/etc/redis.conf" do
  source "redis.conf.erb"
  mode "0644"
  backup false
  notifies :restart, "service[redis-server]", :immediately
end
