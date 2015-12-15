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
# Fire up a 14.04 Ubuntu in AWS

sudo apt-get ruby
rvm --rvmrc --create use 2.2.1@histories-search
gem install rails

sudo apt-get install mysql
mysql -u root -p
# into mysql
create user 'trent_rails'@'localhost' identified by 'railsrails';
grant all privileges on *.* to 'trent_rails'@'localhost';
create database trent_ancestry;
exit
# out of mysql
mysql -u trent_rails --password=railsrails trent_ancestry < mysqldump.ancestry-sample.sql

sudo apt-get install libmysqlclient-dev
gem install mysql

git clone https://github.com/trentlarson/ancestry-history-search.git

rails generate controller ancestors

nohup bin/rails server > rails-server.out 2>&1 &

```
