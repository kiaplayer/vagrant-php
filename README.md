# Vagrantfile & Chef cookbooks for PHP application

This Vagrant environment uses Chef-Solo to install all necessary software and deploy PHP application.

Software versions:
 
 * Ubuntu Trusty 14.04 (32 bit)
 * NGINX (last version from NGINX PPA)
 * PHP 5.6 (from ondrej PPA)
 * Memcached (from Ubuntu default repository)
 * MySQL 5.5 (from Ubuntu default repository)
 * PostgreSQL 9.3 (from PostgreSQL PPA)
 
## Requirements

You must install [Vagrant](http://vagrantup.com), [VirtualBox](https://www.virtualbox.org) and few vagrant plugins:

    $ vagrant plugin install vagrant-librarian-chef-nochef vagrant-omnibus

## How to start

Checkout project from VCS:

    $ git clone <repo> <project_root>

Copy ".chef/Vagrantfile" to project root and start VM:

    $ cd <project_root>
    $ cp .chef/Vagrantfile Vagrantfile
    $ vagrant up

Also you can add records to your local hosts-file (sites should point to ip from Vagrantfile).

## How to integrate your project with this environment

If you already have existent project, then you must checkout it from VCS:

    $ git clone <repo> <project_root>

If you want to create new project (for example, with "composer create-project"), then you must create project root manually:    

    $ mkdir <project_root>

Copy ".chef" folder to project root and modify ".chef/nodes/10.2.2.10.json" and ".chef/Vagrantfile" accordingly to your needs.
Add row "/Vagrantfile" in ".gitignore" file of your project.

Copy ".chef/Vagrantfile" to project root and start VM:

    $ cd <project_root>
    $ cp .chef/Vagrantfile Vagrantfile
    $ vagrant up

If you are creating new project, then you must login on VM over SSH (see "SSH access"), install new project with Composer 
and download it from VM:

    $ composer create-project --prefer-dist yiisoft/yii2-app-basic /home/php-app/www

Also you can add records to your local hosts-file (sites should point to ip from Vagrantfile).

If all works fine you can commit project code in new or existent repository.

## SSH access

You can login on VM over SSH with these ways:

* As administrator: `$ vagrant ssh`
* As application user: `$ ssh php-app@10.2.2.10 -i ".chef/files/id_rsa"`

## "/.chef" folder contents

* `files/` - folder for storing files for recipe "php-app" (these files are accessible inside VM by path "/tmp/.chef/files/...");
* `nodes/` - folder for VM settings;
* `cookbooks/` - external cookbooks downloaded by "librarian-chef" (created automatically);
* `site-cookbooks/` - internal cookbooks for project;
* `tmp/` - temporary folder (created automatically);
* `Cheffile` - cookbooks dependencies for "librarian-chef";
* `solo.rb` - configuration file for Chef-Solo;
* `Vagrantfile` - default template for Vagrantfile.

There are some example json-files in ".chef/nodes" folder for Yii2 applications:

* `yii2_advanced.json` - params for application based on advanced Yii2 template;
* `yii2_basic.json` - params for application based on basic Yii2 template.

Main cookbook "php-app" (in ".chef/site-cookbooks") installs software and deploys project code. 
It does following:

* Create user for application (params ["php-app"]["user"] and ["php-app"]["group"]);
* Create folders (params ["php-app"]["project_dir"] and ["php-app"]["log_dir"]);
* Create php-fpm pools for running application (param ["php-app"]["php"]["pools"]);
* Create Nginx virtual hosts (param ["php-app"]["vhosts"]);
* Add hosts to VM hosts file (param ["php-app"]["hosts"]);
* Create databases (params ["php-app"]["mysql"] and ["php-app"]["pgsql"]);
* Checkout project code from VCS (if necessary, see "Project code location");
* Install Composer and project dependencies (param ["php-app"]["composer"]);
* Execute custom init commands (param ["php-app"]["init_commands"]).

This recipe can be expanded during project development.

If you use Composer in your project, then you should set param ["php-app"]["composer"]["github_auth_token"], 
to increase Github API limits. You can get this token in your Github profile.

### Project code location

You can set project folder with param ["php-app"]["project_dir"]. 
Usually you need to ajust param ["php-app"]["vhosts"]["variables"]["root"] accordingly.

There are two ways to locate project code:

* Project code is located inside shared folder (for example, in "/vagrant");
* Project code is located outside shared folder (for example, in "/home/php-app/www").

There is no need to sync project files between VM and local machine when code is located in shared folder.
But there are some disadvantages:

* All files in shared folder share the same permissions ("777" by default);
* Filenames in shared folder are case-insensitive (with local machine under Windows);
* To create symlinks in shared folder you need to run Vagrant with administrator permissions (with local machine under Windows);
* Slow disk operations inside shared folder in VM (with local machine under Linux, can be resolved by using NFS).

If project code is located outside shared folder (for example, in "/home/user/www") it is more close to real work environment,
but also has some disadvantages:

* Developer must always keep files in sync between VM and local machine (and change VCS branches in two places too);
* Git local commits will not be accessible inside VM.

You should set param ["php-app"]["git"]["repository"] if project code is located outside shared folder.
It allows to checkout project code during vagrant provision. 
Also you should provide access to this repository for a key from ["php-app"]["ssh"]["deployment_key"].

If you are using PhpStorm or IDEA then you can add deployment server to keep files in sync (button "Add" in "File - Settings - Deployment").
Use these settings (it depends on settings in json-file):

* **Type**: SFTP
* **SFTP host**: 10.2.2.10
* **Port**: 22
* **Root path**: /home/php-app/www
* **User name**: php-app
* **Auth type**: Key pair (OpenSSH)
* **Private key file**: local_project_root/.chef/files/id_rsa
* **Passphrase**:
* **Web server root URL**: demo.local
* **Deployment path on server**: /
* **Web path on server**: /

Then you should mark this server as default (button "Use as Default" in "File - Settings - Deployment") and
change param "Upload changed files automatically to the default server" to "Always" or "On explicit save action" in 
"File - Settings - Deployment - Options".

### MySQL configuration

Cookbook "mysql" is used for configuraton of MySQL server (key "mysql" in json-file).

You must set administrator credentials in param ["php-app"]["mysql"]["root_connection"].  
These credentials will be used to create databases. 
You can set administrator password in param ["mysql"]["server_root_password"].

To create database(s) for your application you should set param ["php-app"]["mysql"]["databases"]:

    {
        ...
        "php-app": [
            ...
            "mysql": {
                "root_connection": { "host": "127.0.0.1", "username": "root", "password": "" },
                "databases": [
                    {"name": "yii2advanced", "username": "root", "password": "", "encoding": "utf8", "collation": "utf8_general_ci"},
                    {"name": "yii2_advanced_tests", "username": "root", "password": "", "encoding": "utf8", "collation": "utf8_general_ci"}
                ]
            }
            ...
        ],
        ...
    }

### PosgtreSQL configuration

Cookbook "postgresql" is used for configuraton of PostgreSQL server (key "postgresql" in json-file).

You must set administrator credentials in param ["php-app"]["pgsql"]["root_connection"]. 
These credentials will be used to create databases and users. 
You can set administrator password in param ["postgresql"]["password"]["postgres"]. This password cannot be empty.

To create database(s) for your application you should set param ["php-app"]["pgsql"]["databases"]:

    {
        ...
        "php-app": [
            ...
            "pgsql": {
                "root_connection": { "host": "127.0.0.1", "username": "postgres", "password": "password" },
                "databases": [
                    {"name": "yii2advanced", "username": "yii2advanced", "password": "", "encoding": "UTF8", "collation": "en_US.UTF-8"},
                    {"name": "yii2_advanced_tests", "username": "yii2advanced", "password": "", "encoding": "UTF8", "collation": "en_US.UTF-8"}
                ]
            }
            ...
        ],
        ...
    }

## Remote debug with Xdebug (using PhpStorm or IDEA)

To debug application inside VM you need to add PHP server (button "Add" in "File - Settings - PHP - Servers") with the following settings:

* **Name**: demo.local
* **Host**: demo.local
* **Port**: 80
* **Debugger**: Xdebug
* **Use path mappings**: On (project folder in VM must correspond to ["php-app"]["project_dir"] in json-file)

Then you need to create configuration with type "PHP Web application" (in "Run - Edit configurations") using created PHP server.
