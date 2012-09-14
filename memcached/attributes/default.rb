# Platform specific attributes
case platform
when "redhat","centos","fedora","scientific"
  default[:memcached][:user] = "memcached"
when "ubuntu","debian"
  default[:memcached][:user] = "nobody"
end

# Configuration requirements.
default[:memcached][:port] = "11211"
default[:memcached][:maxconn] = "3072"
default[:memcached][:cachesize] = "128M"
default[:memcached][:options] = ""
