class Recommendation < ActiveRecord::Base
  belongs_to :user
  belongs_to :match, :counter_cache => true
  has_many :contacts
  
  def contacts_as_text
    s="";
    contacts.each{ |p| s+="#{p.email_address.strip}, " }
    s
  end
  
  def contacts_as_text=(contacts_as_text)
    logger.info("contacts_as_text= "+contacts_as_text)
    @contacts_as_text=contacts_as_text
  end
  
  def before_save
     #contacts.each {|c| Contact.destroy(c.id)}
     @contacts_as_text.chomp.split(/,+/).each { |e|
      e.strip!
      contact = Contact.new
      contact.email_address = e
      contact.user_id=user_id
      contacts<<contact
    }
  end
  
  def Recommendation.current_with_text(num=50)
    sql = " select recommendations.* from recommendations,matches "
    sql+= " where recommendations.match_id=matches.id and date_for_sorting>=now() "
    sql+= " and recommendations.text is not null and length(recommendations.text)>5 "
    sql+= " order by created_at desc limit #{num} "
    Recommendation.find_by_sql(sql)
  end
end
