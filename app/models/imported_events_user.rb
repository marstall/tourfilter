class ImportedEventsUser < ActiveRecord::Base
  establish_connection "shared_#{ENV['RAILS_ENV']}" unless $mode=="import_daemon"

  has_one :imported_event
  has_one :user
  
  def ImportedEventsUser.users_for(imported_event,include_author=true)
    subselect = <<-SUBSELECT
      select user_id from tourfilter_shared.imported_events_users ieu  where ieu.imported_event_id=#{imported_event.id} and ieu.deleted_flag=false
    SUBSELECT
    subselect+=" and ieu.user_id<>#{imported_event.user_id} "
    sql = <<-SQL
      select * from users where id in (#{subselect})
    SQL
    User.find_by_sql(sql)
  end

  def ImportedEventsUser.find_future_by_user(user) 
    sql = <<-SQL
      select ieu.* from imported_events_users ieu, imported_events ie
      where ie.id = ieu.imported_event_id
      and ieu.deleted_flag=false
      and ie.date>now() 
      and ieu.user_id=#{user.id}
    SQL
    find_by_sql(sql)
  end
end
