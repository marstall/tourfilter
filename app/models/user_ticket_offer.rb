=begin
CREATE TABLE user_ticket_offers (id int(11) NOT NULL auto_increment,uid char(64) default NULL,user_id int(11) default NULL,match_id int(11) default NULL,price float(11,2) default NULL,quantity int(11) default NULL,section varchar(32) default NULL,row varchar(4) default NULL,created_at datetime default NULL,updated_at datetime default NULL,subject text,body text,match_description varchar(255) default NULL,flag_count int(4) default '0',PRIMARY KEY  (id),KEY match_id (match_id))
=end
#require 'lorem_ipsum.rb'
#require "../../config/environment.rb"

class UserTicketOffer < ActiveRecord::Base

   belongs_to :match
   belongs_to :user

   def UserTicketOffer.find_active_flagged(order2=:popularity,user_id=nil)
     find_all_active_grouped(order2,"u.flag_count>0")
   end

   def UserTicketOffer.find_active_by_user_id(order2=:popularity,user_id=nil)
     find_all_active_grouped(order2,"u.user_id= ?","created_at desc",0,10000,[user_id])
   end
   
   def UserTicketOffer.find_active_by_query(order2=:popularity,query=nil)
     find_all_active_grouped(order2,"u.match_description like ?","created_at desc",0,10000,["%#{query}%"])
   end

   def UserTicketOffer.find_all_active(condition="true",order="created_at desc",offset=0,limit=1000,params=[])
     sql = <<-SQL
      (
        select u.*,date_for_sorting date from user_ticket_offers u,matches
        where u.match_id = matches.id
        and matches.status='notified' and matches.time_status='future'
        and left(matches.date_for_sorting,10)>left(now(),10)
        and #{condition}
      )
      union
      (
        select u.*,'' as date from user_ticket_offers u
        where match_id is null
        and adddate(created_at,interval 2 week)>now()
        and #{condition}
      )
      order by #{order}
      limit 20000
     SQL
     UserTicketOffer.find_by_sql([sql]+params+params)
   end

    def UserTicketOffer.find_all_active_grouped(order2=:popularity,condition="true",order="created_at desc",offset=0,limit=1000,params=[])
      utos = find_all_active(condition,order,offset,limit,params)
      mda = Array.new
      mdh = Hash.new
      date_hash = Hash.new
      matches_utos = Hash.new
      utos.each{|uto|
        md = uto.match_description
        date_hash[md] = uto.match_id ? uto.date : "3000"
        mda<<md unless mdh[md]
        mdh[md]||=0
        mdh[md]+=1
        matches_utos[md]||=Array.new
        matches_utos[md]<<uto
        logger.info "matches_utos[#{md}]:\t\t#{matches_utos[md].size}"
      }
      mda.sort!{|x,y| 
        if order2==:date
          left = date_hash[x]
          right = date_hash[y]
        elsif order2==:popularity
          left = mdh[y].size rescue nil
          right = mdh[x].size rescue nil
        end
        if left and right
          result = left<=>right
        else
          result = left||right
        end
        result
      }
#      mda.sort!{|x,y| date_hash[y]<=>date_hash[x]}
      return mda,matches_utos
      #@matches,@utos_matches = 
    end
end



def main (args)
  num_to_create = 1000
  num_matches = 200
  num_users = 800
  future_matches = Match.current(num_matches)
  users = User.find(:all,:conditions=>"registered_on is not null and name<>'none' and last_visited_on is not null",:order=>"id desc",:limit=>num_users)
  puts "loaded"
  0.upto(num_to_create) {|n|
    uto = UserTicketOffer.new
    match = future_matches[rand(num_matches)]
    uto.match_id = match.id
    uto.user_id = users[rand(num_users)].id
    uto.match_description = match.dropdown_description
    uto.body=lorem_ipsum
    uto.save
    puts "#{uto.id}: #{uto.match_description}: #{uto.body}"
  }
end

# program entry point
#main(ARGV)
