echo "creating $TOURFILTER_HOME/ec2/user_data_file.sh ..."
echo -e "#! \nsource ~/.bash_profile;cd /tourfilter;git pull;git checkout $1;sudo bundle install;sudo apachectl restart;rm public/index.html">$TOURFILTER_HOME/ec2/user_data_file.sh
