class MP3 < ActiveRecord::Base

  belongs_to :term

  def self.count_by_term(term)
    sql="select count(*) from mp3 where term_id=#{term.id}"
    return HypeMachineDatum.count_by_sql(sql)
  end

  def self.find_by_term(term, num=5)
    sql="select * from mp3 where term_id=#{term.id} limit #{num}"
    find_by_sql(sql)
  end

end