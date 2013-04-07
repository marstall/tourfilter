cd ~/tourfilter/daemon
make_new_matches_invalid.sh

ruby import_events_daemon.rb geocode_venues
ruby import_events_daemon.rb put_venues_in_metros

./finalize_event_import_admin.sh
./import_matches_all_metros.sh


