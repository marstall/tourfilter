 mysql -uchris -pchris tourfilter_shared -e"select left(created_at,10) day,count(*) follows from actions where object_type='user' and action='added' group by day;"
  mysql -uchris -pchris tourfilter_shared -e"select left(created_at,10) day,count(*) adds from actions where object_type='term' and action='added' group by day;"
  mysql -uchris -pchris tourfilter_shared -e"select left(created_at,10) day,count(*) registrations from actions where action='registered' group by day;"
