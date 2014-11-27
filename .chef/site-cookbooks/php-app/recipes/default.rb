#------------------------------------------------------------------------------
# PHP application installation
#------------------------------------------------------------------------------

include_recipe 'locale'
include_recipe 'nginx'

# Add application user and group

app_user = node['php-app']['user']
app_group = node['php-app']['group']
app_homedir = "/home/#{app_user}"

group app_group do
    append true
    action :create
end

user app_user do
    supports :manage_home => true
    gid app_group
    home app_homedir
    shell '/bin/bash'
    action :create
end

# Create folders

[ node['php-app']['project_dir'], node['php-app']['log_dir'] ].each do |a_directory|
    directory a_directory do
        owner app_user
        group node['nginx']['group']
        mode '0750'
        recursive true
        action :create
    end
end

ssh_dir = "#{app_homedir}/.ssh"

directory ssh_dir do
    owner app_user
    group app_group
    mode '0700'
    action :create
end

# Set authorized SSH keys

if !node['php-app']['ssh']['authorized_keys'].empty?
    authorized_keys_content = ''
    node['php-app']['ssh']['authorized_keys'].each do |key_file|
        authorized_keys_content += ::File.open(key_file).read
    end
    file "#{ssh_dir}/authorized_keys" do
        content authorized_keys_content
        owner app_user
        group app_group
        mode '0644'
        backup false
        action :create
    end
end

# Set private SSH key (for deployment)

if !node['php-app']['ssh']['deployment_key'].empty?
    file "#{ssh_dir}/id_rsa" do
        content ::File.open(node['php-app']['ssh']['deployment_key']).read
        owner app_user
        group app_group
        mode '0600'
        backup false
        action :create
    end
end

# Set known hosts

if !node['php-app']['ssh']['known_hosts'].empty?
    execute 'set-known-hosts' do
        user app_user
        group app_group
        command 'ssh-keyscan -H ' + node['php-app']['ssh']['known_hosts'].join(' ') + " > #{ssh_dir}/known_hosts"
    end
end

# Install PHP

if !node['php-app']['php']['apt_repository_ppa'].empty?
    include_recipe 'apt'
    apt_repository 'repository_php' do
        uri node['php-app']['php']['apt_repository_ppa']
        distribution node['lsb']['codename']
        components ['main']
        keyserver 'keyserver.ubuntu.com'
        key node['php-app']['php']['apt_repository_key']
    end
end

package 'php5-fpm'

service 'php5-fpm' do
    provider Chef::Provider::Service::Upstart
    action :nothing
end

if !node['php-app']['php']['packages'].empty?
    node['php-app']['php']['packages'].each do |a_package|
        package a_package
    end
end

# Set custom PHP settings

if !node['php-app']['php']['custom_directives'].empty?
    module_name = node['php-app']['php']['custom_module_name'];
    execute 'enable-custom-php-module' do
        command "php5enmod #{module_name}"
        action :nothing
        notifies :restart, 'service[php5-fpm]'
    end
    custom_module_content = ''
    node['php-app']['php']['custom_directives'].each do |key, value|
        custom_module_content += "#{key} = #{value}\n"
    end
    file "/etc/php5/mods-available/#{module_name}.ini" do
        content custom_module_content
        owner 'root'
        group 'root'
        mode '0644'
        action :create
        notifies :run, 'execute[enable-custom-php-module]'
    end
end

# Create PHP-FPM pools

if !node['php-app']['php']['pools'].empty?
    node['php-app']['php']['pools'].each do |a_pool|
        template "/etc/php5/fpm/pool.d/#{a_pool['name']}.conf" do
            source a_pool['template']
            local a_pool['template_local']
            mode '0640'
            owner app_user
            group node['nginx']['group']
            variables(a_pool['variables'])
            notifies :restart, 'service[php5-fpm]'
        end
    end
end

# Create NGINX vhosts

if !node['php-app']['vhosts'].empty?
    node['php-app']['vhosts'].each do |a_vhost|
        vhost_filename = "#{a_vhost['name']}.conf"
        template "/etc/nginx/sites-available/#{vhost_filename}" do
            source a_vhost['template']
            local a_vhost['template_local']
            mode '0600'
            owner app_user
            group app_group
            variables(a_vhost['variables'])
            notifies :reload, 'service[nginx]', :delayed
        end
        nginx_site vhost_filename
    end
end

# Add hosts to hostsfile

if !node['php-app']['hosts'].empty?
    node['php-app']['hosts'].each do |a_ip, a_hosts|
        a_hosts.each do |a_host|
            hostsfile_entry a_ip do
                hostname a_host
                action :append
            end
        end
    end
end

# Install MySQL and create databases

if !node['php-app']['mysql']['databases'].empty?

    include_recipe 'mysql::server'
    include_recipe 'database::mysql'

    node['php-app']['mysql']['databases'].each do |a_database|

        mysql_database_user a_database['username'] do
            connection node['php-app']['mysql']['root_connection']
            password a_database['password']
            action :create
        end

        mysql_database a_database['name'] do
            connection node['php-app']['mysql']['root_connection']
            owner a_database['username']
            encoding a_database['encoding'] || 'utf8'
            collation a_database['collation'] || 'utf8_general_ci'
            action :create
        end

    end

end

# Install PostgreSQL and create databases

if !node['php-app']['pgsql']['databases'].empty?

    if node['postgresql']['enable_pgdg_apt']
        include_recipe 'postgresql::apt_pgdg_postgresql'
        # Fix for package "libpq-dev": https://github.com/hw-cookbooks/postgresql/issues/171
        e = execute 'apt-get update' do
            action :nothing
        end
        e.run_action(:run)
    end

    include_recipe 'postgresql::config_initdb'
    include_recipe 'postgresql::server'
    include_recipe 'database::postgresql'

    node['php-app']['pgsql']['databases'].each do |a_database|

        postgresql_database_user a_database['username'] do
            connection node['php-app']['pgsql']['root_connection']
            password a_database['password']
            action :create
        end

        postgresql_database a_database['name'] do
            connection node['php-app']['pgsql']['root_connection']
            owner a_database['username']
            encoding a_database['encoding'] || 'UTF8'
            collation a_database['collation'] || 'en_US.UTF-8'
            action :create
        end

    end

end

# Install Composer

if node['php-app']['composer']['enable']

    package 'git'

    composer_dir = "#{app_homedir}/.composer"

    [ composer_dir, "#{composer_dir}/vendor", "#{composer_dir}/vendor/bin" ].each do |path|
        directory path do
            owner app_user
            group app_group
            mode '0755'
            action :create
        end
    end

    link "#{app_homedir}/bin" do
        to "#{composer_dir}/vendor/bin"
    end

    unless ENV['PATH'].include? ":#{app_homedir}/bin"
        ENV['PATH'] += ":#{app_homedir}/bin"
    end

    ENV['COMPOSER_HOME'] = composer_dir

    package 'curl'
    execute 'install-composer' do
        user app_user
        group app_group
        command "curl -sS https://getcomposer.org/installer | php -- --install-dir=#{composer_dir} --filename=composer.phar"
        creates "#{composer_dir}/composer.phar"
    end

    link "#{composer_dir}/vendor/bin/composer" do
        to "#{composer_dir}/composer.phar"
    end

    # Add Github access token to increase API limits

    if !node['php-app']['composer']['github_auth_token'].empty?
        file "#{composer_dir}/auth.json" do
            content JSON.generate({'github-oauth' => {'github.com' => node['php-app']['composer']['github_auth_token']}})
            owner app_user
            group app_group
            mode '0600'
            backup false
            action :create
        end
    end

    # Install global requirements

    if !node['php-app']['composer']['global_requirements'].empty?
        execute 'install-composer-global-requirements' do
            user app_user
            group app_group
            cwd app_homedir
            command 'composer global require ' + node['php-app']['composer']['global_requirements'].join(' ')
        end
    end

end

project_root = node['php-app']['project_dir']

# Checkout project code from VCS

if !node['php-app']['git']['repository'].empty?

    package 'git'

    git project_root do
        repository node['php-app']['git']['repository']
        revision node['php-app']['git']['revision']
        user app_user
        group app_group
        action :sync
    end

end

# Install project dependencies

if node['php-app']['composer']['enable']

    dev_option = node['php-app']['composer']['dev'] ? '--dev' : '--no-dev'
    execute 'install-composer-project-dependencies' do
        user app_user
        group app_group
        cwd project_root
        command "composer install #{dev_option}"
        only_if { File.exists?("#{project_root}/composer.json") }
    end

end

# Execute init commands

if !node['php-app']['init_commands'].empty?
    node['php-app']['init_commands'].each do |a_command|
        execute a_command do
            user app_user
            group app_group
            cwd project_root
            command a_command
        end
    end
end
