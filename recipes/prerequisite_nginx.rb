id = 'gogs'

node.default['modern_nginx']['with_ipv6'] = \
  node[id]['gogs']['frontend']['with_ipv6']

include_recipe 'modern_nginx::default'
