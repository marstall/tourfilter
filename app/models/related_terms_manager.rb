=begin
  problem: most popular artists are too frequently recommended
  why: even people who track obscure artists also like some popular artists, like radiohead
  possible to make a list of the 10 most similar artists to an artist
  possible also to make a list of the 10 artists for which an artist is highest on their similarity list? is it different?
  
  ok we go through related_terms and make a list of (related_term_text,count)
  we then take all the related_terms and delete 
  

=end

=begin
  CREATE TABLE `term_edges` (
    `id` int(11) NOT NULL auto_increment,
    `created_at` datetime default NULL,
    `l` varchar(64) default NULL,
    `r` varchar(64) default NULL,
    `metro_code` varchar(64) default NULL,
    `network` varchar(64) default NULL,
    `user_id` varchar(64) default NULL,
    `username` varchar(64) default NULL,
    `match_id` varchar(64) default NULL,
    `place_name` varchar(64) default NULL,
    `date` datetime default NULL,
    `url` varchar(64) default NULL,
    PRIMARY KEY  (`id`),
    index (l,metro_code,network,r)
  )

=end

  # related algorithm
  # for each metro, go through all terms
  # for each term, make records like this
  # term1 --- user1 --- term2
  # term1 --- user1 --- term3
  # term1 --- user2 --- term2
  # term1 --- match1 --- term4
  # term1 --- match1 --- term5

  # then summarize this full graph:
  # loop through each unique left side term
  # for each term, make an order list of the most linked-to right side terms for each network: match and user
  # create a record for each pairing like:
  # term1 --- 560 users -- 4 shows played with -- rank 4560 -- term2
  # term1 --- 60 users -- 0 shows played with -- rank 60 -- term3

  # this summary table can be queried like so to get the most related terms for a given term:
  #     select right from related_terms
  #     where left = 'stars' order by rank desc


  # also make a 
  # for each new entry, create a graph item term with 
  def connect_to_metro_database(metro)
    ActiveRecord::Base.establish_connection(
      :adapter=>"mysql",
      :host=>"localhost",
      :database=> "tourfilter_#{metro.code}")
  end

  def generate_user_network(metro)
    puts "generating user network ..."
    sql = <<-SQL
      select l.text lt,tul.user_id user_id,r.text rt
      from terms l, terms_users tul,terms_users tur, terms r
      where l.id=tul.term_id 
      and tul.user_id=tur.user_id
      and tur.term_id=r.id
      and l.num_trackers>=5  
      and r.num_trackers>=5
      and l.text like "a%"
    SQL
    terms = Term.find_by_sql(sql)
    terms.each{|term|
      term_edge = TermEdge.new
      term_edge.metro_code=metro.code
      term_edge.l = term.lt
      term_edge.r = term.rt
      term_edge.network='user'
      term_edge.user_id=term.user_id
#      term_edge.username=user.name
      term_edge.save
      puts "#{term_edge.l} U #{term_edge.r}"
    }
=begin
    Term.all_alpha.each{|lterm|
#      lterm.fast_user_terms.each_with_index
      lterm.users.each_with_index{|user,i|
          user.terms.each{|rterm|
            term_edge = TermEdge.new
            term_edge.metro_code=metro.code
            term_edge.l = lterm.text
            term_edge.r = rterm.text
            term_edge.network='user'
            term_edge.user_id=user.id
            term_edge.username=user.name
            term_edge.save
            puts "#{term_edge.l} U #{term_edge.r}"
          }
      }
    }
=end
  end

  def generate_played_with_network(metro)
    puts "generating played-with network ..."
    matches = Match.find_by_sql("select * from matches where status='notified' and day is not null")
    matches.each_with_index{|match,j|
      terms = match.playing_with(50)
      lterm = match.term
      page = match.page
      place_name = page.place.name rescue ""
      terms.each_with_index{|rterm,i|
          term_edge = TermEdge.new
          term_edge.metro_code=metro.code
          term_edge.l = lterm.text rescue next
          term_edge.r = rterm.text
          term_edge.network='played_with'
          term_edge.place_name = place_name 
          term_edge.url = page.url rescue ''
          term_edge.date = match.date_for_sorting
          term_edge.match_id=match.id
          term_edge.save
          puts "#{metro.code} | #{j}/#{matches.size}\t#{term_edge.l} P #{term_edge.r} #{term_edge.place_name} #{term_edge.date.month}/#{term_edge.date.day}/#{term_edge.date.year}"
        }
      }
  end

=begin
select l,r,count(*) cnt 
from term_edges 
where l='ad frank'
and network='played_with'
group by l,r 
order by l,cnt;
=end

  def reduce_played_with_network(metro)
    sql = "select distinct l from term_edges where network='played_with' order by l "
#    sql = "select distinct l from term_edges where l='mean creek' order by l"
    term_edges = TermEdge.find_by_sql(sql)
    term_edges.each_with_index{|term_edge,i|
      puts "[#{i+1}/#{term_edges.size}] scoring for #{term_edge.l}"
      sql = <<-SQL
        select l,r,count(*) cnt 
        from term_edges 
        where l=?
        and network='played_with'
        group by r 
        order by cnt asc
      SQL
      tes = TermEdge.find_by_sql([sql,term_edge.l])
      tes.each{|te|
        rt = RelatedTerm.find_by_term_text_and_related_term_text(te.l,te.r)
        nw = ""
        if not rt
          nw = " *"
          rt = RelatedTerm.new
          rt.term_text=te.l
          rt.related_term_text=te.r
          rt.count=0
        end
        rt.played_with_count||=0
        rt.played_with_count+=te.cnt.to_i
        rt.calculate_score
        rt.save
        puts "#{metro.code} | #{te.l}:#{te.r} played_with: #{rt.played_with_count} score: #{rt.score} #{nw}"
        }
      }
  end

  def generate_played_with_scores
    metros = Metro.find_all_active
#    metros=Metro.find_by_sql("select * from metros")
    metros.each{|metro|
      connect_to_metro_database(metro)
      header metro.code
#      begin
        generate_played_with_network(metro)
        reduce_played_with_network(metro)
#      rescue
#        puts "couldn't connect to database tourfilter_"+metro.code
#      end
#      generate_played_with_network(metro)
    }
  end

  def clear_played_with_graph
    puts "deleting [played_with] network in term_edges ..."
    TermEdge.delete_all(["network=?","played_with"])
    puts "zeroing out related_terms.played_with_count and related_terms.score ... "
    RelatedTerm.update_all("played_with_count=0,score=0")
  end

  def clear_and_generate_played_with_scores
    clear_played_with_graph
    generate_played_with_scores
  end

=begin  
  def reduce_graph
    # then summarize this full graph:
    # loop through each unique left side term
    # for each term, make an order list of the most linked-to right side terms for each network: match and user
    # create a record for each pairing like:
    # term1 --- 560 users -- 4 shows played with -- rank 4560 -- term2
    # term1 --- 60 users -- 0 shows played with -- rank 60 -- term3

    # this summary table can be queried like so to get the most related terms for a given term:
    #     select right from related_terms
    #     where left = 'stars' order by rank desc
    metros=Metro.find_all_by_code("boston")
    metros.each{|metro|
      connect_to_metro_database(metro)
      header metro.code
      reduce_played_with_network(metro)
    }
  end
=end
