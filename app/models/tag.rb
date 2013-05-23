class Tag < ActiveRecord::Base
  unless $mode=="import_daemon"
    require "../config/environment.rb" if $mode=="daemon"
    establish_connection "shared_#{ENV['RAILS_ENV']}" 
    @cnn='shared'
  end
  
  has_many :taggings

  def Tag.SUPERTAGS
    [
      ["music","music"], 
      ["theatre","theatre"],
      ["art","art"],
      ["comedy","comedy"],
      ["dance","dance"],
      ["movie","movie"],
      ["reading","reading"],
      ["community","community"]
    ]
  end
  
  def Tag.super_and_popular
  	tags = Tag.SUPERTAGS
    	Tag.popular(20).each{|tag|
      	tags<<["#{tag.text}","##{tag.text} (#{tag.cnt})"]
    	}
    return tags
  end
  
  def Tag.find_by_prefix(prefix)
    sql = <<-SQL
      select tags.*,count(*) cnt from tags,taggings,imported_events where text like ?
      and tags.id=taggings.tag_id
      and taggings.imported_event_id=imported_events.id
      and (imported_events.date>now() or imported_events.end_date>now())
      group by tag_id
      order by cnt desc
      limit 7
    SQL
    
    Tag.find_by_sql([sql,"#{prefix}%"])
  end
  
  
  
  def Tag.is_supertag(tag)
    return nil unless tag
    Tag.SUPERTAGS.each{|st|
      return true if (st[0]==tag)
      }
    return false
  end

  def Tag.popular(num=20)
    sql = <<-SQL
      select text,count(*) cnt from tags,taggings,imported_events
      where taggings.tag_id=tags.id
      and taggings.imported_event_id=imported_events.id
      and imported_events.date>now()
      group by text
      order by cnt desc limit ?
    SQL
    Tag.find_by_sql([sql,num])
  end

  def Tag.find_or_create(_text)
    _text.gsub!("#","")
    _text.strip!
    tag = Tag.find_by_text(_text)
    if not tag
      tag = Tag.new(:text=>_text)
      tag.save
    end
    return tag
  end
end
