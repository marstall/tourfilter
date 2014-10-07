  @@metro_codes=nil
  
  def map_connect (map,path,hash=nil)
    original_path=path
    original_hash=hash
#    puts hash.inspect if hash

    #@@metro_codes=@@metro_codes||Metro.find_all.collect{|metro|metro.code}.join("|")
    metro_codes="montreal|phoenix|albuquerque|asheville|atlanta|austin|baltimore|boston|boulder|buffalo|chicago|cincinnati|cleveland|columbus|dallas|dc|denver|detroit|dublin|elpaso|fargo|greensboro|honolulu|houston|indianapolis|jacksonville|kansascity|lasvegas|london|losangeles|louisville|madison|melbourne|memphis|miami|milwaukee|nashville|neworleans|newyork|oklahomacity|omaha|orlando|philadelphia|pittsburgh|portland|providence|raleighdurham|rochester|sanantonio|sandiego|search|seattle|sf|stlouis|toronto|tucson|tulsa|twincities|vancouver|virginiabeach|westernmass|wichita|search|kingston_upon_hull|stoke_on_trent|leicester|brighton|edinburgh|sheffield|southhampton|liverpool|cardiff|belfast|leeds|manchester|glasgow|newcastle|nottingham|bristol|aberdeen|portsmouth"
    path = "/#{path}" unless path =~ /^\//
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

    if original_path =='/'
#      puts "path: #{path}"
#      puts "hash: #{hash.inspect}"
#      puts "original_path: #{original_path}"
#      puts "original_hash: #{original_hash.inspect}"
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
  map.connect  '/by_venue',
              :controller   => "edit",
              :action       => "by_venue"
  map.connect '/sitemap.rdf',
              :controller   => "edit",
              :action       => "sitemap"
  map_connect map,"/compare_tickets/:id/:term_text/:place_name",
              :controller   => "compare_tickets",
              :action       => "compare_tickets"
  map_connect map,"/venues",
              :controller   => "edit",
              :action       => "venues"
  map_connect map,"/combined",
              :controller   => "edit",
              :action       => "combined"
  map_connect map, '/mushroom/:id/:offset',
              :controller   => "edit",
              :action       => "mushroom",
              :requirements => {
                                :id => /.*/,
                                :offset => /.*/
                                }              
  map_connect map, '/flyers',
              :controller   => "feature",
              :action       => "flyers"
  map_connect map, '/features/:match_id/:term_text/:place_name',
              :controller   => "feature",
              :action       => "feature",
              :requirements => {
                                :match_id => /.*/
                                }              
  map_connect map, '/mushroom/:id',
              :controller   => "edit",
              :action       => "mushroom",
              :requirements => {
                                :id => /.*/,
                                }              
  map_connect map, '/combined/:id/:offset',
              :controller   => "edit",
              :action       => "combined",
              :requirements => {
                                :id => /.*/,
                                :offset => /.*/
                                }              
  map_connect map, '/combined/:id',
              :controller   => "edit",
              :action       => "combined",
              :requirements => {
                                :id => /.*/,
                                }              
  map_connect map,"/mushroom",
              :controller   => "edit",
              :action       => "mushroom"
              
  map_connect map,"/date",
              :controller   => "edit",
              :action       => "date"
  map_connect map,"/featured_playlist/:id",
              :controller   => "xspf",
              :action       => "featured_playlist",
              :requirements => {:id => /.+/}
  map_connect map,"/lala_popup/:term_text",
              :controller   => "edit",
              :action       => "lala_popup",
              :requirements => {:term_text => /.+/}
  map_connect map,"/trackers/:term_text",
              :controller   => "bands",
              :action       => "trackers",
              :requirements => {:term_text => /.+/}
  map_connect map,"/metros",
              :controller   => "edit",
              :action       => "metros"
  map_connect map,"/r",
              :controller   => "redirect",
              :action       => "redirect"
  map_connect map,"/o/:id",
              :controller   => "redirect",
              :action       => "onsale_mail_ticket_redirect"
  map_connect map,"/n/:id",
              :controller   => "redirect",
              :action       => "normal_mail_ticket_redirect"
  map_connect map,"/m/:id",
              :controller   => "redirect",
              :action       => "monthly_newsletter_ticket_redirect"
  map_connect map,"/w/:id",
              :controller   => "redirect",
              :action       => "weekly_newsletter_ticket_redirect"
  map_connect map,"/unsubscribe/:id/:auth_token",
              :controller   => "settings",
              :action       => "unsubscribe",
              :requirements => {:id => /.*/,
                                :auth_token => /.*/}
  map_connect map,"/venues/:id",
              :controller   => "clubs",
              :action       => "index",
              :requirements => {:id => /.+/}
  map_connect map,"/clubs/:id",
              :controller   => "clubs",
              :action       => "index",
              :requirements => {:id => /.+/}
  map_connect map,"/more/:id",
              :controller   => "edit",
              :action       => "more",
              :requirements => {:id => /.+/}
  map_connect map,"/browse_bands",
              :controller   => "browse_bands",
              :action       => "browse_bands"
  map_connect map,"/browse_bands/:letter",
              :controller   => "browse_bands",
              :action       => "browse_bands",
              :requirements => {:letter => /\w/}
  map_connect map, "/show_comments/:name/:id",
              :controller   => "bands",
              :action       => "show_comments",
              :requirements => {:name => /.*/,
                                :id => /.*/}
  map_connect map, "/bands/handler",
              :controller   => "bands",
              :action       => "handler"
  map_connect map, "/bands/test",
              :controller   => "bands",
              :action       => "test"
  map_connect map, "/bands/redbox_test",
              :controller   => "bands",
              :action       => "redbox_test"
  map.connect "search",
              :controller   => "search",
              :action       => "search"
  map.connect "search/search_results",
              :controller   => "search",
              :action       => "search_results"
  map.connect "facebook",
              :controller   => "facebook",
              :action       => "facebook"
  map.connect "facebook/facebook",
              :controller   => "facebook",
              :action       => "facebook"
  map.connect "search/:format/:query",
              :controller   => "search",
              :action       => "search",
              :requirements => {:format => /.+/,
                                :query => /.+/}
  map.connect "search/:query",
              :controller   => "search",
              :action       => "search",
              :requirements => {:query => /.+/}
  map.connect "/search_auto_suggest/.+",
              :controller   => "search",
              :action       => "search_auto_suggest",
              :requirements => {:summary => /.*/}
  map_connect map, "/edit",
              :controller   => "edit",
              :action       => "edit"
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
              :action       => "basic_signup"
  map_connect map, "/lastfm",
              :controller   => "edit",
              :action       => "lastfm"
  map_connect map, "/feed",
              :controller   => "edit",
              :action       => "feed"
  map_connect map, "/itunes",
              :controller   => "edit",
              :action       => "itunes"
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
  map_connect map, "/env",
              :controller   => "admin",
              :action => "env"
  map_connect map, "/admin",
              :controller   => "admin",
              :action => "index"
  map_connect map, "/admin/set_image/:url/:referer",
              :controller   => "admin",
              :action => "set_image",
              :requirements =>{:url => /.*/,:referer => /.*/}
  map_connect map, "/admin/set_image",
              :controller   => "admin",
              :action => "set_image",
              :requirements =>{:url => /.*/,:referer => /.*/}
  map_connect map, "/sources",
              :controller   => "sources",
              :action => "index"
  map_connect map, "/notes",
              :controller   => "notes",
              :action => "index"
  map_connect map, "/sitemap.xml",
              :controller   => "edit",
              :action       => "sitemap"
  map_connect map, "/ical/about",
              :controller   => "ical",
              :action       => "about"
  map_connect map, "/submit_show",
              :controller   => "add_show",
              :action       => "submit_show"
  map_connect map, "/have_want_tickets",
              :controller   => "user_tickets",
              :action       => "user_tickets2"
  map_connect map, "/delete_uto/:id",
              :controller   => "user_tickets",
              :action       => "delete_uto",
              :requirements => {:id => /\d+/}              
  map_connect map, "/flag_uto/:id",
              :controller   => "user_tickets",
              :action       => "flag_uto",
              :requirements => {:id => /\d+/}              
  map_connect map, "/unflag_uto/:id",
              :controller   => "user_tickets",
              :action       => "unflag_uto",
              :requirements => {:id => /\d+/}              
  map_connect map, "/have_want_tickets/post",
              :controller   => "user_tickets",
              :action       => "sell_tickets"
  map_connect map, "/delete_submitted_show/:id",
              :controller   => "add_show",
              :action       => "delete_submitted_show",
              :requirements => {:id => /.*/}
  map_connect map, "/user_submitted_shows",
              :controller   => "add_show",
              :action       => "user_submitted_shows"
  map_connect map, "/user_submitted_shows/:id",
              :controller   => "add_show",
              :action       => "user_submitted_shows",
              :requirements => {:id => /.*/}
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
              :requirements => {:sort => /(by_concert_date|featured)?/}
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
  map_connect map, "/xspf_popup",              
                   :controller   => "xspf",    
                   :action       => "xspf_popup"
  map_connect map, "/xspf/:sort/:id",
              :controller   => "xspf",
              :action       => "index",
              :requirements => {:sort => /by_date_added|by_concert_date|random|by_club_name|by_num_trackers|featured/,
                                :id => /.+/}
                
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
  map_connect map, "/bands/mini_register",
              :controller   => "bands",
              :action       => "mini_register"
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
  map_connect map, "/welcome/:registration_code",
              :controller   => "invitation",
              :action       => "welcome",
              :requirements => {:registration_code => /.*/}
  map_connect map, "/invite",
              :controller   => "invitation",
              :action       => "invite"
  map_connect map, "/locate",
              :controller   => "locate",
              :action       => "locate"
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
              :action       => "expire_term_caches",
              :requirements => {:term_id => /.*/}              
  map_connect map, "/data/recommended_matches/:user_id",
              :controller   => "data",
              :action       => "recommended_matches"
  map_connect map, "/data/shared_terms/:user_id",
              :controller   => "data",
              :action       => "shared_terms"
  map_connect map, "/data/is_youser_recommendee/:user_id",
              :controller   => "data",
              :action       => "is_youser_recommendee"
  map_connect map, '/co',
              :controller   => "edit",
              :action       => "co"
  map_connect map, '/co_signup',
              :controller   => "edit",
              :action       => "co_signup"
  map_connect map, '',
              :controller   => "edit",
              :action       => "homepage"
  map_connect map,"/show/:match_id/:autologin_code",
              :controller   => "edit",
              :action       => "show",
              :requirements => {
                                  :match_id => /[0-9]+/,
                                  :autologin_code => /[0-9a-z]{8}/i
                                }              
              
  map_connect map, '/add_bands/:autologin_code',
              :controller   => "edit",
              :action       => "add_bands"
  map_connect map, '/concerts',
              :controller   => "edit",
              :action       => "concerts_homepage"
  map_connect map, '/login',
              :controller   => "edit",
              :action       => "login"
  map_connect map, '/logout',
              :controller   => "edit",
              :action       => "logout"
  map_connect map, 'homepage_old',
              :controller   => "edit",
              :action       => "homepage"
  map_connect map, 'homepage_old',
              :controller   => "edit",
              :action       => "homepage"
  map_connect map, 'homepage',
              :controller   => "edit",
              :action       => "homepage"
  map_connect map, 'homepage/:id/:offset',
              :controller   => "edit",
              :action       => "homepage",
              :requirements => {
                                :id => /.*/,
                                :offset => /.*/
                                }              
  map_connect map, 'just_calendar/:id/:offset',
              :controller   => "edit",
              :action       => "just_calendar",
              :requirements => {
                                :id => /.*/,
                                :offset => /.*/
                                }              
  map_connect map, 'homepage/:id',
              :controller   => "edit",
              :action       => "homepage",
              :requirements => {:id => /.*/}              
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
              :controller   => "bands",
              :action       => "bands",
              :requirements => {:id => /[\%\'\.\s\w\d\!\?\&\+\*-]+/}
  map_connect map, ':controller'
  map_connect map, ':controller/:action'
  map_connect map, ':controller/:action/:id'
end
