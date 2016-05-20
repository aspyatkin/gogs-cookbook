id = 'gogs'

node.default['go']['version'] = node[id][:go][:version]
node.default['go']['platform'] = node[id][:go][:platform]
node.default['go']['scm'] = false
node.default['go']['packages'] = []
node.default['go']['from_source'] = true

include_recipe 'golang::default'
include_recipe 'golang::packages'
