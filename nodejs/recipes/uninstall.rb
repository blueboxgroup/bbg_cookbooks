yum_package "yum remove nodejs" do
  package_name "nodejs"
  action :remove
end
