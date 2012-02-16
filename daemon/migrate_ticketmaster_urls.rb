require "~/tourfilter/config/environment.rb"

      venues = TicketmasterVenue.find_all_by_source("ticketmaster")
      venues.each{|venue|
        venue.url="http://www.ticketmaster.com/json/search/event?vid=#{venue.code}"
        venue.save
        puts venue.url if venue.events_last_imported>10
      }

