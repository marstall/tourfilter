class PlaceMailer < ActionMailer::Base

  def place_update(user,metro,metro_code,old_place,new_place,sent_at = Time.now)
    admins = User.find_all_admins
    return if not admins
    admin_emails = admins.collect{|admin| admin.email_address}
    
    changes_text="Changes:\r\n"
    changes_text+="name: #{old_place.name} => #{new_place.name}\r\n" if old_place.name!=new_place.name
    changes_text+="url: #{old_place.url} => #{new_place.url}\r\n" if old_place.url!=new_place.url
    changes_text+="ticket_url: #{old_place.ticket_url} => #{new_place.ticket_url}\r\n" if old_place.ticket_url!=new_place.ticket_url
    changes_text+="date_type: #{old_place.date_type} => #{new_place.date_type}\r\n" if old_place.date_type!=new_place.date_type
    changes_text+="date_regexp: #{old_place.date_regexp} => #{new_place.date_regexp}\r\n" if old_place.date_regexp!=new_place.date_regexp
    changes_text+="day_regexp: #{old_place.day_regexp} => #{new_place.day_regexp}\r\n" if old_place.day_regexp!=new_place.day_regexp
    changes_text+="time_type: #{old_place.time_type} => #{new_place.time_type}\r\n" if old_place.time_type!=new_place.time_type
    changes_text+="start_date: #{old_place.start_date} => #{new_place.start_date}\r\n" if old_place.start_date!=new_place.start_date
    changes_text+="end_date: #{old_place.end_date} => #{new_place.end_date}\r\n" if old_place.end_date!=new_place.end_date
    changes_text+="status: #{old_place.status} => #{new_place.status}\r\n" if old_place.status!=new_place.status
    changes_text+="date_status: #{old_place.date_status} => #{new_place.date_status}\r\n" if old_place.date_status!=new_place.date_status
#    changes_text+=": #{old_place.} => #{new_place.}\r\n" if old_place.!=new_place.
    if old_place.pages_as_text.strip!=new_place.pages_as_text.strip
      changes_text+="\r\nListing urls were changed.\r\nOld Listing Urls:\r\n"
      changes_text+=old_place.pages_as_text
      changes_text+="New Listing Urls:\r\n"
      changes_text+=new_place.pages_as_text
    end
    changes_text+="\r\nNotes"
    if new_place.notes!=old_place.notes
      changes_text+=" (changed):\r\n"
    else
      changes_text+=" (not changed):\r\n"
    end
    changes_text+=new_place.notes+"\r\n"
    
    @subject    = "#{user.name} changed #{old_place.name.downcase}"
    @body["user"]                 = user
    @body["old_place"]            = old_place
    @body["changes_text"]       = changes_text
    @body["metro"]                = metro
    @body["metro_code"]                = metro_code
    @recipients = admin_emails
    @from       = "tourfilter #{metro.downcase} admin <info@tourfilter.com>"
    @sent_on    = sent_at
    @headers    = {}
  end
end
