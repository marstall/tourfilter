cd $TOURFILTER_HOME/daemon
rm -rf $TOURFILTER_HOME/log/event_daemon.log 
ruby import_events_daemon.rb import_ticketmaster_tickets search>$TOURFILTER_HOME/log/event_daemon.log
