#!
[[ -s "/home/ec2-user/.rvm/scripts/rvm" ]] && source "/home/ec2-user/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

rvm use ruby-1.8.7-p358

tag= `ec2-metadata | grep user-data |  cut -d: -f2`
echo tag
cd /tourfilter
git pull
git checkout $tag
bundle install
rm public/index.html