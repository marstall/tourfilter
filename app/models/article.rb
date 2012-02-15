class Article < ActiveRecord::Base

  establish_connection "shared"
  
  def already_exists?
    Article.find_by_term_text_and_url(term_text,url)
  end
  
  def Article.find_priority(term_text)
    Article.find_by_sql(["select * from articles where term_text=? and priority is not null order by priority",term_text])
  end

end
