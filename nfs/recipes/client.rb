case node[:platform]
when "centos","redhat","fedora"
  %w(nfs-utils nfs-utils-lib portmap).each do |pkg|
    yum_package pkg do
      arch node[:kernel][:machine]
      action :install
    end
  end

  %w(portmap netfs).each do |srv|
    service srv do
      action [ :enable, :start ]
    end
  end
end