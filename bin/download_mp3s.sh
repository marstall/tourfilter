cd /home/chris/tourfilter/daemon
mkdir /home/chris/tourfilter/public/mp3s
chmod -R a+wr /home/chris/tourfilter/public/mp3s
ruby check_remote_mp3s.rb $1 download_mp3s
