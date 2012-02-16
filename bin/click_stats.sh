mysql tourfilter_shared -uchris -pchris -e"select left(user_agent,50),count(*) cnt from external_clicks group by left(user_agent,50) order by cnt asc;"
mysql tourfilter_shared -uchris -pchris -e"select domain,count(*) cnt from external_clicks group by domain order by cnt asc ;"
mysql tourfilter_shared -uchris -pchris -e"select metro_code,count(*) cnt from external_clicks group by metro_code order by cnt asc ;"
mysql tourfilter_shared -uchris -pchris -e"select source,count(*) cnt from external_clicks group by source order by cnt asc;"
mysql tourfilter_shared -uchris -pchris -e"select link_source,count(*) cnt from external_clicks group by link_source order by cnt asc;"
mysql tourfilter_shared -uchris -pchris -e"select page_type,count(*) cnt from external_clicks group by page_type order by cnt asc;"
mysql tourfilter_shared -uchris -pchris -e"select page_section,count(*) cnt from external_clicks group by page_section order by cnt asc;"

