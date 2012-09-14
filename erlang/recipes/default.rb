erlang_package = "erlang"

case node[:platform]
when "centos","redhat","scientific"
yum_package erlang_package do
  arch node[:kernel][:machine]
end
when "debian","ubuntu"
  apt_package erlang_package
end
