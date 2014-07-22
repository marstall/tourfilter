cd $TOURFILTER_HOME/daemon
echo "using environment $RAILS_ENV ..."

echo m shared "update artist_terms set status='valid' where status='new' and match_probability='likely'"
m shared "update artist_terms set status='valid' where status='new' and match_probability='likely'"
echo m shared "update artist_terms set status='invalid' where status='new' and match_probability='unlikely'"
m shared "update artist_terms set status='invalid' where status='new' and match_probability='unlikely'"

for name in $(m shared "select code from metros where status='active' order by code asc")
do
 if [ $name != "code" ]; then 
        echo $name :
 ruby import_events_daemon.rb make_matches_from_imported_events metro $name
fi
done
