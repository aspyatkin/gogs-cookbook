module ChefCookbook
  class Gogs
    def initialize(node)
      @node = node
    end

    def self.postgres_root_username
      'postgres'
    end

    def postgres_user_password(username)
      ::Chef::EncryptedDataBagItem.load(
        'postgres',
        @node.chef_environment
      )['credentials'].fetch(username, nil)
    end

    def postgres_connection_info
      id = 'gogs'
      root_username = self.class.postgres_root_username

      {
        host: @node[id]['postgres']['listen']['address'],
        port: @node[id]['postgres']['listen']['port'],
        username: root_username,
        password: postgres_user_password(root_username)
      }
    end
  end
end
