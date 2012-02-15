  @@metro_codes=nil
  
  def map_connect (map,path,hash=nil)
    original_path=path
    original_hash=hash
    puts path.inspect
    puts hash.inspect if hash

    #@@metro_codes=@@metro_codes||Metro.find_all.collect{|metro|metro.code}.join("|")
     metro_codes="atlanta|austin|boston|chicago|dallas|dc|detroit|dublin|facebook|houston|london|losangeles|melbourne|montreal|nashville|neworleans|newyork|philadelphia|portland|providence|remixed|seattle|sf|toronto|twincities|vancouver|westernmass|search"
    path="/:metro_code#{path}"
    hash||={}
    hash[:requirements]||={}
    hash[:requirements][:metro_code]=/#{metro_codes}/
    map.connect(path,hash)

    if original_hash
      map.connect(original_path,original_hash)
    else
      map.connect(original_path)
    end
  end

ActionController::Routing::Routes.draw do |map|
  # Add your own custom routes here.
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Here's a sample route:
  # map_connect map, 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  # map_connect map, '', :controller => "welcome"

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'

  # Install the default route as the lowest priority.
  map_connect map, "/show_comments/:name/:id",
              :controller   => "bands",
              :action       => "show_comments",
              :requirements => {:name => /.*/,
                                :id => /.*/}
  map_connect map, "/bands/handler",
              :controller   => "bands",
              :action       => "handler"
  map_connect map, "/search",
              :controller   => "search",
              :action       => "search"
  map_connect map, "/search/search_results",
              :controller   => "search",
              :action       => "search_results"
  map_connect map, "/facebook",
              :controller   => "facebook",
              :action       => "facebook"
  map_connect map, "/search/:query",
              :controller   => "search",
              :action       => "search",
              :requirements => {:query => /.+/}
  map_connect map, "/search/:format/:query",
              :controller   => "search",
              :action       => "search",
              :requirements => {:format => /.+/,
                                :query => /.+/}
  map_connect map, "/search_auto_suggest/.+",
              :controller   => "search",
              :action       => "search_auto_suggest",
              :requirements => {:summary => /.*/}
              
  map_connect map, "/edit",
              :controller   => "edit",
              :action       => "edit"
  map_connect map, "/me",
              :controller   => "edit",
              :action       => "me"
  map_connect map, "/me/:username",
              :controller   => "edit",
              :action       => "me",
              :requirements => {:username => /[\w\d_\-]+/}
  map_connect map, "/private_message/send/:id",
              :controller   => "private_message",
              :action       => "send_message",
              :requirements => {:id => /.*/}
  map_connect map, "/signup",
              :controller   => "edit",
              :action       => "signup"
  map_connect map, "/basic_signup",
              :controller   => "edit",
              :action       => "basic_signup"
  map_connect map, "/recommendations",
              :controller   => "recommendations",
              :action       => "index"
  map_connect map, "/track/:id",
              :controller   => "track",
              :action       => "index",
              :requirements => {:id => /.*/}
  map_connect map, "/accept_invite/:id",
              :controller   => "invitation",
              :action       => "accept",
              :requirements => {:id => /.*/}
  map_connect map, "/www",
              :controller   => "www",
              :action       => "index"
  map_connect map, "/calendar",
              :controller   => "calendar",
              :action => "index"
  map_connect map, "/admin",
              :controller   => "admin",
              :action => "index"
  map_connect map, "/sources",
              :controller   => "sources",
              :action => "index"
  map_connect map, "/notes",
              :controller   => "notes",
              :action => "index"
  map_connect map, "/ical/about",
              :controller   => "ical",
              :action       => "about"
  map_connect map, "/rss/about",
              :controller   => "rss",
              :action       => "about"
  map_connect map, "/rss/sms_tonight",
              :controller   => "rss",
              :action       => "sms_tonight"
  map_connect map, "/ical/:user_name",
              :controller   => "ical",
              :action       => "index",
              :requirements => {:user_name => /[\w\d\-_]+/}
  map_connect map, "/ical",
              :controller   => "ical",
              :action       => "index"
  map_connect map, "/podcast",
              :controller   => "rss",
              :action       => "podcast"
  map_connect map, "/rss/:sort",
              :controller   => "rss",
              :action       => "index",
              :requirements => {:sort => /(by_concert_date)?/}
  map_connect map, "/rss/:user_name/:sort",
              :controller   => "rss",
              :action       => "index",
              :requirements => {:user_name => /[\w\d\-_]+/,
                                :sort => /by_concert_date/}
  map_connect map, "/rss/:user_name",
              :controller   => "rss",
              :action       => "index",
              :requirements => {:user_name => /[\w\d_\-]+/}
  map_connect map, "/:user_name/feed.pcast",
              :controller   => "rss",
              :action       => "podcast_link",
              :requirements => {:user_name => /[\w\d_\-]+/}
  map_connect map, "/xspf",
              :controller   => "xspf",
              :action       => "index"
  map_connect map, "/xspf/:sort",
              :controller   => "xspf",
              :action       => "index",
              :requirements => {:sort => /by_date_added|by_concert_date|random|by_club_name|by_num_trackers/}
  map_connect map, "/rss",
              :controller   => "rss",
              :action       => "index"
  map_connect map, "/feed.pcast",
              :controller   => "rss",
              :action       => "podcast_link"
  map_connect map, "/show_badge/:username",
              :controller   => "user",
              :action       => "show_badge",
              :requirements => {:username => /[\w\d_\-]+/}

#  map_connect map, "/users/:username/mini/:num",
#              :controller   => "user",
#              :action       => "mini",
#              :requirements => {:username => /[\w\d-]*/,
#                                :num => /\d*/}
  map_connect map, "/badge/:username",
              :controller   => "user",
              :action       => "badge",
              :requirements => {:username => /[\w\d_\-]+/}
  map_connect map, "/badge/:username/:num",
              :controller   => "user",
              :action       => "badge",
              :requirements => {
                :username => /[\w\d_-]*/,
                :num => /[\d]+/
                }
  map_connect map, "/badge/:username/:num/:title",
              :controller   => "user",
              :action       => "badge",
              :requirements => {
                :username => /[\w\d_-]*/,
                :num => /[\d\w]+/,
                :title => /.+/
                }
  map_connect map, "/users/:username/",
              :controller   => "user",
              :action       => "index",
              :requirements => {:username => /[\w\d\-_]+/}
  map_connect map, "/users/all_bands/:username/",
              :controller   => "user",
              :action       => "all_bands",
              :requirements => {:username => /[\w\d\-_]+/}
  map_connect map, "/clubs",
              :controller   => "clubs",
              :action       => "club_listings",
              :requirements => {:id => /.+/}
  map_connect map, "/clubs/:id",
              :controller   => "clubs",
              :action       => "index",
              :requirements => {:id => /.+/}
  map_connect map, "/bands/mini_register/:id",
              :controller   => "bands",
              :action       => "mini_register",
              :requirements => {:id => /[\d\&\.\'\w]+/}
  map_connect map, "/bands/admin/:id",
              :controller   => "bands",
              :action       => "admin",
              :requirements => {:id => /[\d\&\.\'\w]+/}
  map_connect map, "/bands/:id",
              :controller   => "bands",
              :action       => "index",
              :requirements => {:id => /[\d\&\.\'\w]+/}
  map_connect map, "/data/track_click/:url",
              :controller   => "data",
              :action       => "track_click",
              :requirements => {:url => /.*/}
  map_connect map, "/data/track_click/:url/:referer",
              :controller   => "data",
              :action       => "track_click",
              :requirements => {:url => /.*/,
                                :referer => /.*/
                                }
  map_connect map, "/welcome",
              :controller   => "invitation",
              :action       => "welcome"
  map_connect map, "/invite",
              :controller   => "invitation",
              :action       => "invite"
  map_connect map, "/invite_friends",
              :controller   => "invitation",
              :action       => "invite"
  map_connect map, "/recently_added_shows",
              :controller   => "edit",
              :action       => "recently_added_shows"
  map_connect map, "/recently_added_shows/:start/:num",
              :controller   => "edit",
              :action       => "recently_added_shows"
  map_connect map, "/recent_users/:start/:num",
              :controller   => "edit",
              :action       => "recent_users"
  map_connect map, "/data/expire_match_caches/:match_id",
              :controller   => "data",
              :action       => "expire_match_caches"
  map_connect map, "/data/expire_term_caches/:term_id",
              :controller   => "data",
              :action       => "expire_term_caches"
  map_connect map, "/data/recommended_matches/:user_id",
              :controller   => "data",
              :action       => "recommended_matches"
  map_connect map, "/data/shared_terms/:user_id",
              :controller   => "data",
              :action       => "shared_terms"
  map_connect map, "/data/is_youser_recommendee/:user_id",
              :controller   => "data",
              :action       => "is_youser_recommendee"
  map_connect map, '/',
              :controller   => "edit",
              :action       => "index"
  map_connect map, 'homepage',
              :controller   => "edit",
              :action       => "homepage"
  map_connect map, 'place',
              :controller   => "place",
              :action       => "index"
  map_connect map, 'edit/right_column/:mode',
              :controller   => "edit",
              :action       => "right_column",
              :requirements => {:mode => /[\w\d-]*/}
  map_connect map, 'edit',
              :controller   => "edit",
              :action       => "edit"
  map_connect map, 'home',
              :controller   => "home",
              :action       => "index"
  map_connect map, 'listings',
              :controller   => "browse",
              :action       => "index"
  map_connect map, 'about',
              :controller   => "about",
              :action       => "index"
  map_connect map, 'etc',
              :controller   => "etc",
              :action       => "index"
  map_connect map, 'settings',
              :controller   => "settings",
              :action       => "index"
  map_connect map, 'step3',
              :controller   => "settings",
              :action       => "step3"
  map_connect map, 'lost_password',
              :controller   => "lost_password",
              :action       => "index"
  map_connect map, 'metros',
              :controller   => "metros",
              :action       => "index"
  map_connect map, ":id",
              :controller   => "application",
              :action       => "bands_wrapper",
              :requirements => {:id => /[\%\'\.\s\w\d\!\?\&\+\*-]+/}
  map_connect map, ':controller'
  map_connect map, ':controller/:action'
  map_connect map, ':controller/:action/:id'
  puts map.inspect
end
