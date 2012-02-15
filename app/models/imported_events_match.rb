class ImportedEventsMatch < ActiveRecord::Base

  validates_uniqueness_of :description

  def match
    Match.find(match_id)
  end
  

  def imported_event
    ImportedEvent.find(imported_event_id)
  end
end
