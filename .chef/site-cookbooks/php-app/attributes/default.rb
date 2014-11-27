default['php-app']['user'] = 'php-app'
default['php-app']['group'] = 'www-data'
default['php-app']['project_dir'] = '/home/php-app/www'
default['php-app']['log_dir'] = '/home/php-app/log'

default['php-app']['ssh']['authorized_keys'] = []
default['php-app']['ssh']['deployment_key'] = ''
default['php-app']['ssh']['known_hosts'] = []

default['php-app']['git']['repository'] = ''
default['php-app']['git']['revision'] = 'master'

default['php-app']['php']['apt_repository_ppa'] = 'ppa:ondrej/php5-5.6'
default['php-app']['php']['apt_repository_key'] = 'E5267A6C'

default['php-app']['php']['packages'] = [
    'php5-fpm',
    'php5-cli',
    'php5-mysql',
    'php5-pgsql',
    'php5-sqlite',
    'php-apc',
    'php5-memcached',
    'php5-gd',
    'php5-mcrypt',
    'php5-curl',
    'php5-intl',
    'php5-xdebug',
]

default['php-app']['php']['custom_module_name'] = 'app'
default['php-app']['php']['custom_directives'] = {
    'engine'                     => 'Off',
    'expose_php'                 => 'Off',
    'short_open_tag'             => 'Off',
    'error_reporting'            => -1,
    'display_errors'             => 'On',
    'display_startup_errors'     => 'On',
    'track_errors'               => 'On',
    'log_errors'                 => 'On',
    'error_log'                  => '/var/log/php_errors.log',
    'cgi.fix_pathinfo'           => 0,
    'date.timezone'              => 'Europe/Moscow',
    'xdebug.remote_enable'       => 1,
    'xdebug.remote_connect_back' => 1,
}

default['php-app']['php']['pools'] = [
    {
        'name' => 'php-app',
        'template' => 'php-fpm-pool.conf.erb',
        'template_local' => false,
        'variables' => {
            'user' => 'php-app',
            'group' => 'www-data',
            'listen' => '/var/run/php-fpm.php-app.sock',
        },
    }
]

default['php-app']['vhosts'] = [
    {
        'name' => 'demo.local',
        'template' => 'nginx-vhost.conf.erb',
        'template_local' => false,
        'variables' => {
            'url' => 'demo.local',
            'root' => '/home/php-app/www',
            'access_log' => '/home/php-app/log/demo.local-access.log',
            'error_log' => '/home/php-app/log/demo.local-error.log',
            'socket' => '/var/run/php-fpm.php-app.sock',
            'index' => 'index.php',
            'allow_custom_scripts_execution' => true,
        },
    }
]

default['php-app']['hosts'] = {
    '127.0.0.1' => [ 'demo.local' ]
}

default['php-app']['mysql'] = {
    'root_connection' => { 'host' => '127.0.0.1', 'username' => 'root', 'password' => '' },
    'databases' => []
}

default['php-app']['pgsql'] = {
    'root_connection' => { 'host' => '127.0.0.1', 'username' => 'postgres', 'password' => 'password' },
    'databases' => []
}

default['php-app']['composer']['enable'] = true
default['php-app']['composer']['github_auth_token'] = ''
default['php-app']['composer']['dev'] = true
default['php-app']['composer']['global_requirements'] = []

default['php-app']['init_commands'] = []
