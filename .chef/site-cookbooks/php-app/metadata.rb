name             'php-app'
description      'Installs and configures PHP application with Nginx, PHP-FPM and MySQL/PostgreSQL'
maintainer       'Ilya Krylov'
maintainer_email 'kiaplayer@gmail.com'
license          'MIT'
version          '1.0.0'

supports         'ubuntu'

%w{ apt
    database
    hostsfile
    locale
    mysql
    nginx
    postgresql
}.each do |cb|
    depends cb
end
