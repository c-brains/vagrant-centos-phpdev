# SELinux 無効化
service 'selinux' do
  action :disable
end

# Apache(httpd) インストール
package 'httpd' do
  action :install
end

# Apache用の設定ファイルをテンプレートから作成する
remote_file '/etc/httpd/conf/httpd.conf' do
  source 'templates/httpd/httpd.conf'
  mode '644'
  owner 'root'
  group 'root'
end

# VirtualHost 用設定ディレクトリ作成
directory '/etc/httpd/vhosts.d' do
  action :create
  mode '755'
  owner 'root'
  group 'root'
end

# 開発環境用VirtualHost設定
remote_file '/etc/httpd/vhosts.d/localhost.conf' do
  source 'templates/httpd/localhost.conf'
  mode '644'
  owner 'root'
  group 'root'
end

# PHPインストール
%w(php php-mysql php-mbstring).each do |pkg|
  package pkg do
    action :install
  end
end

# composer インストール
execute "composer インストール" do
  command "curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer"
  not_if "test $(which /usr/local/bin/composer)"
end


# MariaDBインストール
%w(mariadb-server mariadb).each do |pkg|
  package pkg do
    action :install
  end
end

# 自動起動
service 'mariadb' do
  action :enable
end
service 'mariadb' do
  action :start
end

# MariaDB rootパスワード変更
execute "MariaDB rootパスワード変更" do
  command "/bin/mysqladmin -u root password #{node.mariadb.root_password}"
  # パスワードなしでログインできるときのみ変更する
  only_if "/bin/mysql -u root -e 'show databases;'"
end

# Timezone が使えるように
execute "Timezone が使えるようにする" do
  command "/bin/mysql_tzinfo_to_sql /usr/share/zoneinfo | /bin/mysql -u root mysql -p#{node.mariadb.root_password}"
  only_if ("test \"$(/bin/mysql -e \"SELECT CONVERT_TZ('2015-04-02 12:00:00', 'GMT', 'America/New_York');\" -p#{node.mariadb.root_password} --silent --skip-column-names)\" == 'NULL'")
end

# アプリケーション用データベース作成
execute "アプリケーション用データベース作成" do
  command "/bin/mysql -e \"CREATE DATABASE #{node.mariadb.db_name} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;\" -uroot -p#{node.mariadb.root_password}"
  only_if ("test \"$(/bin/mysql -e \"SHOW DATABASES LIKE '#{node.mariadb.db_name}';\" -uroot -p#{node.mariadb.root_password} --silent --skip-column-names)\" != '#{node.mariadb.db_name}'")
end

# アプリケーション用権限作成
execute "アプリケーション用権限作成" do
  command "/bin/mysql -e \"GRANT ALL PRIVILEGES ON #{node.mariadb.db_name}.* TO '#{node.mariadb.user_name}'@'localhost' IDENTIFIED BY '#{node.mariadb.user_password}';\" -uroot -p#{node.mariadb.root_password}"
  only_if ("test \"$(/bin/mysql -e \"SELECT User FROM mysql.user WHERE Host='localhost' AND User='#{node.mariadb.user_name}';\" -uroot -p#{node.mariadb.root_password} --silent --skip-column-names)\" != '#{node.mariadb.user_name}'")
end
# FLUSH PRIVILEGES
execute "FLUSH PRIVILEGES" do
  command "/bin/mysql -e \"FLUSH PRIVILEGES;\" -uroot -p#{node.mariadb.root_password}"
end

# httpd 再起動
service 'httpd' do
  action :restart
end

# NetworkManager起動時(service network restart)時に /resolv.confに書き込まれる
remote_file '/etc/NetworkManager/dispatcher.d/99-dns-option' do
  source 'templates/NetworkManager/99-dns-option'
  mode '644'
  owner 'root'
  group 'root'
end
