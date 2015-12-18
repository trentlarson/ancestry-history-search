# ancestry-history-search

On my current plaform this just gives an error 500 with no output in
any logs, no matter how I tweak my configs.  If I can use 2011
versions of Ruby and Rails then I'd go for this option; all the file
contents are in the "old" folder.

I built from scratch on a 2015 plaform, and it actually seems to
load OK but when I submit my form it gives me this error: `No route
matches [POST] "/view"` Here are the build instructions for that
version:


```
# Fire up a 14.04 Ubuntu in AWS, and SSH in and do the following... probably in a subdirectory

sudo apt-get update
sudo apt-get install git
git clone https://github.com/trentlarson/ancestry-history-search.git

sudo apt-get install mysql-server
mysql -u root -p
# into mysql
create user 'trent_rails'@'localhost' identified by 'railsrails';
grant all privileges on *.* to 'trent_rails'@'localhost';
exit
# out of mysql
mysql -u trent_rails --password=railsrails
# into mysql
create database trent_ancestry;
exit
# out of mysql
mysql -u trent_rails --password=railsrails trent_ancestry < ancestry-history-search/histories-sample.mysqldump.sql

sudo apt-get install ruby
#gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
#\curl -sSL https://get.rvm.io | bash -s stable
#rvm --rvmrc --create use 2.2.1@histories-search

sudo apt-get install libmysqlclient-dev
gem install mysql

gem install rails
rails generate controller histories
cd histories
cp -rp ../ancestry-history-search/app/controllers/histories_controller.rb app/controllers/
cp -rp ../ancestry-history-search/app/models/individual.rb app/models/
cp -rp ../ancestry-history-search/app/views/histories/view.html.erb app/views/histories/
cp -rp ../ancestry-history-search/config/database.yml config/
cp -rp ../ancestry-history-search/public/stylesheets/default.css public/stylesheets

bin/rails server > rails-server.out 2>&1 &

```
