cd ~/tourfilter/daemon
rm -rf ~/tourfilter/log/event_daemon.log 
ruby import_events_daemon.rb import_ticketmaster_tickets import_ticketmaster_uk_tickets search>~/tourfilter/log/event_daemon.log
