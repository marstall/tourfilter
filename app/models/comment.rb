class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :match,
    :counter_cache => true
  validates_length_of :text, :in => 1..1024

  def validate
    text !~ /http|href|cialis|viagra|url/i
  end

  def before_save
    text = text.gsub(/<([^>]+)>/," ") if text # get rid of all html
    return false if not validate
  end

  def render_errors
    s = "<ul>"
  	errors.each{|error|
  	  s+="<li>#{error}</li>"
    }
    s+="</ul>"
  end

end