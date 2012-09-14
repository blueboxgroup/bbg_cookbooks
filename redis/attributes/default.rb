# Installation requirements.
default[:redis][:version] = "2.4.8"
default[:redis][:dir] = "/usr/local/redis"
default[:redis][:dirs] = %w(bin etc log run)
default[:redis][:binaries] = %w(redis-benchmark redis-cli redis-server redis-check-aof redis-check-dump)

# Configuration requirements.
default[:redis][:daemonize] = "yes"
default[:redis][:pidfile] = "#{node[:redis][:dir]}/run/redis.pid"
default[:redis][:port] = "6379"
default[:redis][:bind] = "0.0.0.0"
default[:redis][:timeout] = "300"
default[:redis][:loglevel] = "notice"
default[:redis][:logfile] = "#{default[:redis][:dir]}/log/redis.log"
default[:redis][:databases] = "16"
default[:redis][:appendonly] = "no"
default[:redis][:appendfsync] = "everysec"
default[:redis][:no_appendfsync_on_rewrite] = "no"
default[:redis][:vm_enabled] = "no"
default[:redis][:vm_swap_file] = "/tmp/redis.swap"
default[:redis][:vm_max_memory] = "0"
default[:redis][:vm_page_size] = "32"
default[:redis][:vm_pages] = "134217728"
default[:redis][:vm_max_threads] = "4"
default[:redis][:glueoutputbuf] = "yes"
default[:redis][:hash_max_zipmap_entries] = "64"
default[:redis][:hash_max_zipmap_value] = "512"
default[:redis][:activerehashing] = "yes"
