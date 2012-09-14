case node[:platform]
when "centos","redhat","fedora"
  if File.exist?("/proc/user_beancounters") and node[:network][:default_interface].include?("venet")
    log("This appears to be a VPS! The NFS server recipe does not support VPSes at this time.") { level :fatal }
    log("See the following URL: https://thevault.blueboxgrid.com/index.php/NFS_Server_on_a_VPS") { level :fatal }
  else
    %w(nfs-utils nfs-utils-lib portmap).each do |pkg|
      yum_package pkg do
        arch node[:kernel][:machine]
        action :install
      end
    end

    %w(portmap nfs nfslock).each do |srv|
      service srv do
        action [ :enable, :start ]
      end
    end
  end
end