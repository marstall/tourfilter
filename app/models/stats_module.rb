module StatsModule

  def number_of_emails(days=7)
    sql = <<-SQL
      select left(created_at,10) dt, count(*) cnt 
      from events 
        where action='create' and object_type='email'
        group by dt 
        order by dt desc 
        limit #{days}
    SQL
    a = Array.new
    a<<["date","num emails"]
    rows = ActiveRecord::Base.connection.select_all(sql)
    rows.each{|row|
      a<<[row['dt'],row['cnt']]
      }
  #  append_show_page_views_column(a,days)    
    return a
  end
  
  def num_show_views(days)
    sql = <<-SQL
      select left(created_at,10) dt, count(*) cnt 
      from events 
        where action='view' and object_type='show'
        group by dt 
        order by dt desc 
        limit #{days}
    SQL
    rows = ActiveRecord::Base.connection.select_all(sql)

    a = Array.new
    a<<["date","show page views"]
    
    rows.each_with_index{|row,i|
      a<<[row['dt'],row['cnt']]
      }
    return a
  end
=begin  
  def append_show_page_views_column(a,days)
    sql = <<-SQL
      select left(created_at,10) dt, count(*) cnt 
      from events 
        where action='view' and object_type='show'
        group by dt 
        order by dt desc 
        limit #{days}
    SQL
    rows = ActiveRecord::Base.connection.select_all(sql)
    
    rows.each_with_index{|row,i|
      dt = row['dt']
      if dt
      a[i+1]<<row['cnt']
      }
    return a
  end
=end
  def generate_stats(cache=false)
    stats = Hash.new
    stats["emails last 14 days"]=number_of_emails(14) #test_stats
    stats["show views last 7 days"]=num_show_views(7) #test_stats
    #stats = test_stats
    return stats
  end
  
  def test_stats
    arr=Array.new
    arr<<["day","sent","clicked"]
    arr<<["4/1","200","20"]
    arr<<["4/2","100","10"]
    return arr
  end
end