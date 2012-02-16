mysql -uchris -pchris tourfilter_shared -e"select left(created_at,10) dt,count(*) cnt from external_clicks where link_source='mail'  group by dt order by dt;"
