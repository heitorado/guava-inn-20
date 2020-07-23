server 'guava-inn.tech', user: 'deploy', roles: %w{app db web}

set :ssh_options, forward_agent: true
