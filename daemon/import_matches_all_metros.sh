for name in $(m shared "select code from metros order by code asc")
do
 if [ $name != "code" ]; then 
        echo $name :
 ruby import_events_daemon.rb make_matches_from_imported_events metro $name
fi
done
