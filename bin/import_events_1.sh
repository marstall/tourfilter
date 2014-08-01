cd $TOURFILTER_HOME/daemon
rm -rf $TOURFILTER_HOME/log/event_daemon.log 
ssh -t marstall@psychoastronomy.org "bash -c '~/node/out/Release/node ~/proxy/proxy.js'" &
ruby import_events_daemon.rb import_ticketmaster_tickets search
#ruby import_events_daemon.rb import_ticketmaster_tickets search>$TOURFILTER_HOME/log/event_daemon.log
