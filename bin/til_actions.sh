mysql -uchris -pchris tourfilter_shared -e"select left(created_at,10) day,count(*) follows from actions where right(created_at,8)<right(now(),8) and  object_type='user' and action='added' group by day;"
mysql -uchris -pchris tourfilter_shared -e"select left(created_at,10) day,count(*) adds from actions where right(created_at,8)<right(now(),8) and object_type='term' and action='added' group by day"
mysql -uchris -pchris tourfilter_shared -e"select left(created_at,10) day,count(*) registrations from actions where right(created_at,8)<right(now(),8) and  action='registered' group by day;"

