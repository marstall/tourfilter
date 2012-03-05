#!

tag= `ec2-metadata | grep user-data |  cut -d: -f2`
cd /tourfilter
echo $tag>bootstrap_tag
git pull
git checkout $tag
rm public/index.html

[[ -s "/home/ec2-user/.rvm/scripts/rvm" ]] && source "/home/ec2-user/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

rvm use ruby-1.8.7-p358
bundle install

