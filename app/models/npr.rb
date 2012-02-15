require 'rubygems'
require 'mechanize'
require 'json'

class Npr
  def initialize(logger)
    @logger = logger
  end
  
  def log (s)
    if @logger!=nil
      @logger.info s 
    else
      puts s
    end
  end

  include UrlFetcher
#  API_KEY="MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001" 
  API_KEY="MDA0MzgzOTg2MDEyNTg5MjE2ODllNDk3MQ001" 

 def npr_url(artist_id,sources,num=1,offset=0)
#   "http://www.tourfilter.com/about/feeds"
  "http://api.npr.org/query?id=#{artist_id}&fields=title,audio,#{Time.now.to_s.gsub(/\s/,'')}&output=JSON&apiKey=#{API_KEY}"
 end

 def fetch_npr_json(artist_id,num)
   url = npr_url(artist_id,num+5)
   puts url
   body = fetch_url_no_cache(url)
   JSON.parse(body)
 end

 def story_results_for_term(term_text,num=5)
   npr_artist = NprArtist.find_by_normalized_name(Term.normalize_text(term_text))
   return [] unless npr_artist
   json = fetch_npr_json(npr_artist.artist_id,num)
#   json = fetch_npr_json(2,num)
   results = json['list']['story']
#   return results[0..num-1] if num>0
#   return []
  return results
 end

end
=begin
{
    "version": "0.93",
    "list": {
        "title": {
            "$text": "NPR: Sonic Youth"
        },
        "teaser": {
            "$text": "Sonic Youth artist page: interviews, features and/or performances archived at NPR Music"
        },
        "miniTeaser": {
            
        },
        "link": {
            "type": "api",
            "$text": "http://api.npr.org/query/query?id=15373040&apiKey=MDA0MzgzOTg2MDEyNTg5MjE2ODllNDk3MQ001"
        },
        "link": {
            "type": "html",
            "$text": "?ft=3&f=15373040"
        },
        "story": [
            {
                "id": "104383868",
                "link": [
                    {
                        "type": "html",
                        "$text": "http://www.npr.org/templates/story/story.php?storyId=104383868&ft=3&f=15373040"
                    },
                    {
                        "type": "api",
                        "$text": "http://api.npr.org/query?id=104383868&apiKey=MDA0MzgzOTg2MDEyNTg5MjE2ODllNDk3MQ001"
                    }
                ],
                "title": {
                    "$text": "Sonic Youth: A Six-Minute Ode To Britney"
                },
                "teaser": {
                    "$text": "Sonic Youth's \"Malibu Gas Station\" is almost certainly the greatest six-minute opus ever written about Britney Spears. That's assuming, of course, that the song <em>is</em> about Spears, an idea supported by lines that seem to refer to her childhood performing career and recent erratic behavior."
                }
            },
            {
                "id": "99909658",
                "link": [
                    {
                        "type": "html",
                        "$text": "http://www.npr.org/templates/story/story.php?storyId=99909658&ft=3&f=15373040"
                    },
                    {
                        "type": "api",
                        "$text": "http://api.npr.org/query?id=99909658&apiKey=MDA0MzgzOTg2MDEyNTg5MjE2ODllNDk3MQ001"
                    }
                ],
                "title": {
                    "$text": "Turning 'Sonic Youth' Fans Into Readers"
                },
                "teaser": {
                    "$text": "The iconic 80s indie band Sonic Youth has captivated generations of free thinkers, anarchists and artists. Now it has also inspired a group of people to turn dissonance into literature. Curator Peter Wild discusses his new collection, <em>Noise: Fiction Inspired by Sonic Youth.</em>"
                },
                "show": [
                    {
                        "program": {
                            "id": "17",
                            "code": "DAY",
                            "$text": "Day to Day"
                        },
                        "showDate": {
                            "$text": "Tue, 27 Jan 2009 13:00:00 -0500"
                        },
                        "segNum": {
                            "$text": "10"
                        }
                    }
                ],
                "audio": [
                    {
                        "id": "99909619",
                        "type": "primary",
                        "title": {
                            
                        },
                        "duration": {
                            "$text": "0"
                        },
                        "format": {
                            "mp3": {
                                "type": "m3u",
                                "$text": "http://api.npr.org/m3u/199909619-5122b0.m3u?orgId=1&topicId=1105&ft=3&f=15373040"
                            },
                            "wm": {
                                "$text": "http://www.npr.org/templates/dmg/dmg_wmref_em.php?id=99909619&type=1&mtype=WM&orgId=1&topicId=1105&ft=3&f=15373040"
                            },
                            "rm": {
                                "$text": "http://www.npr.org/templates/dmg/dmg_rpm.rpm?id=99909619&type=1&mtype=RM&orgId=1&topicId=1105&ft=3&f=15373040"
                            }
                        },
                        "rightsHolder": {
                            
                        },
                        "permissions": {
                            "download": {
                                "allow": "true"
                            },
                            "stream": {
                                "allow": "true"
                            },
                            "embed": {
                                "allow": "true"
                            }
                        }
                    }
                ]
            },
            {
                "id": "91461342",
                "link": [
                    {
                        "type": "html",
                        "$text": "http://www.npr.org/templates/story/story.php?storyId=91461342&ft=3&f=15373040"
                    },
                    {
                        "type": "api",
                        "$text": "http://api.npr.org/query?id=91461342&apiKey=MDA0MzgzOTg2MDEyNTg5MjE2ODllNDk3MQ001"
                    }
                ],
                "title": {
                    "$text": "Sonic Youth: Story of a 'Kool Thing'"
                },
                "teaser": {
                    "$text": "The highly influential band has been crazy on stage for decades, but its members lead a surprisingly normal real life, according to David Browne, author of <em>Goodbye 20th Century: A Biography of Sonic Youth</em>."
                },
                "show": [
                    {
                        "program": {
                            "id": "47",
                            "code": "BPP",
                            "$text": "The Bryant Park Project"
                        },
                        "showDate": {
                            "$text": "Fri, 13 Jun 2008 07:00:00 -0400"
                        },
                        "segNum": {
                            "$text": "8"
                        }
                    }
                ],
                "audio": [
                    {
                        "id": "91461303",
                        "type": "primary",
                        "title": {
                            
                        },
                        "duration": {
                            "$text": "0"
                        },
                        "format": {
                            "mp3": {
                                "type": "m3u",
                                "$text": "http://api.npr.org/m3u/191461303-3b46d0.m3u?orgId=1&topicId=1105&ft=3&f=15373040"
                            },
                            "wm": {
                                "$text": "http://www.npr.org/templates/dmg/dmg_wmref_em.php?id=91461303&type=1&mtype=WM&orgId=1&topicId=1105&ft=3&f=15373040"
                            },
                            "rm": {
                                "$text": "http://www.npr.org/templates/dmg/dmg_rpm.rpm?id=91461303&type=1&mtype=RM&orgId=1&topicId=1105&ft=3&f=15373040"
                            }
                        },
                        "rightsHolder": {
                            
                        },
                        "permissions": {
                            "download": {
                                "allow": "true"
                            },
                            "stream": {
                                "allow": "true"
                            },
                            "embed": {
                                "allow": "true"
                            }
                        }
                    }
                ]
            },
            {
                "id": "14384946",
                "link": [
                    {
                        "type": "html",
                        "$text": "http://www.npr.org/templates/story/story.php?storyId=14384946&ft=3&f=15373040"
                    },
                    {
                        "type": "api",
                        "$text": "http://api.npr.org/query?id=14384946&apiKey=MDA0MzgzOTg2MDEyNTg5MjE2ODllNDk3MQ001"
                    }
                ],
                "title": {
                    "$text": "Surveying Sonic Youth's 'Daydream Nation'"
                },
                "teaser": {
                    "$text": "Fresh Air's music critic Milo Miles considers the work of the art-punk band Sonic Youth; the group's 1988 album <em>Daydream Nation</em> has just been reissued in a deluxe double-CD edition."
                },
                "show": [
                    {
                        "program": {
                            "id": "13",
                            "code": "FA",
                            "$text": "Fresh Air from WHYY"
                        },
                        "showDate": {
                            "$text": "Thu, 13 Sep 2007 11:00:00 -0400"
                        },
                        "segNum": {
                            "$text": "2"
                        }
                    }
                ],
                "audio": [
                    {
                        "id": "14384935",
                        "type": "primary",
                        "title": {
                            
                        },
                        "duration": {
                            "$text": "0"
                        },
                        "format": {
                            "mp3": {
                                "type": "m3u",
                                "$text": "http://api.npr.org/m3u/114384935-c0adea.m3u?orgId=1&topicId=1104&aggIds=4465028&ft=3&f=15373040"
                            },
                            "wm": {
                                "$text": "http://www.npr.org/templates/dmg/dmg_wmref_em.php?id=14384935&type=1&mtype=WM&orgId=1&topicId=1104&aggIds=4465028&ft=3&f=15373040"
                            },
                            "rm": {
                                "$text": "http://www.npr.org/templates/dmg/dmg_rpm.rpm?id=14384935&type=1&mtype=RM&orgId=1&topicId=1104&aggIds=4465028&ft=3&f=15373040"
                            }
                        },
                        "rightsHolder": {
                            
                        },
                        "permissions": {
                            "download": {
                                "allow": "true"
                            },
                            "stream": {
                                "allow": "true"
                            },
                            "embed": {
                                "allow": "true"
                            }
                        }
                    }
                ]
            },
            {
                "id": "6609925",
                "link": [
                    {
                        "type": "html",
                        "$text": "http://www.npr.org/templates/story/story.php?storyId=6609925&ft=3&f=15373040"
                    },
                    {
                        "type": "api",
                        "$text": "http://api.npr.org/query?id=6609925&apiKey=MDA0MzgzOTg2MDEyNTg5MjE2ODllNDk3MQ001"
                    }
                ],
                "title": {
                    "$text": "Sonic Youth's B-Sides Are Worthwhile and Strong"
                },
                "teaser": {
                    "$text": "Sonic Youth, the avant-garde rock band from New York, has released a new album called <em>Destroyed Room</em>, a collection of previously unreleased tracks and B-sides from the band's last 12 years."
                },
                "show": [
                    {
                        "program": {
                            "id": "17",
                            "code": "DAY",
                            "$text": "Day to Day"
                        },
                        "showDate": {
                            "$text": "Tue, 12 Dec 2006 13:00:00 -0500"
                        },
                        "segNum": {
                            "$text": "11"
                        }
                    }
                ],
                "audio": [
                    {
                        "id": "6609930",
                        "type": "primary",
                        "title": {
                            "$text": "Listen"
                        },
                        "duration": {
                            "$text": "0"
                        },
                        "format": {
                            "mp3": {
                                "type": "m3u",
                                "$text": "http://api.npr.org/m3u/16609930-d936d0.m3u?orgId=1&topicId=1104&aggIds=4465028&ft=3&f=15373040"
                            },
                            "wm": {
                                "$text": "http://www.npr.org/templates/dmg/dmg_wmref_em.php?id=6609930&type=1&mtype=WM&orgId=1&topicId=1104&aggIds=4465028&ft=3&f=15373040"
                            },
                            "rm": {
                                "$text": "http://www.npr.org/templates/dmg/dmg_rpm.rpm?id=6609930&type=1&mtype=RM&orgId=1&topicId=1104&aggIds=4465028&ft=3&f=15373040"
                            }
                        },
                        "rightsHolder": {
                            
                        },
                        "permissions": {
                            "download": {
                                "allow": "true"
                            },
                            "stream": {
                                "allow": "true"
                            },
                            "embed": {
                                "allow": "true"
                            }
                        }
                    }
                ]
            },
            {
                "id": "5541160",
                "link": [
                    {
                        "type": "html",
                        "$text": "http://www.npr.org/templates/story/story.php?storyId=5541160&ft=3&f=15373040"
                    },
                    {
                        "type": "api",
                        "$text": "http://api.npr.org/query?id=5541160&apiKey=MDA0MzgzOTg2MDEyNTg5MjE2ODllNDk3MQ001"
                    }
                ],
                "title": {
                    "$text": "Sonic Youth: The First Quarter-Century"
                },
                "teaser": {
                    "$text": "When Sonic Youth began in 1981, the critical and commercial success they would achieve was unimaginable. Though it began as an experiment in guitar noise and feedback, the group has cemented its legacy as one of the most important acts of its era."
                },
                "show": [
                    {
                        "program": {
                            "id": "39",
                            "code": "WC",
                            "$text": "World Cafe"
                        },
                        "showDate": {
                            "$text": "Mon, 21 Aug 2006 14:00:00 -0400"
                        },
                        "segNum": {
                            "$text": "1"
                        }
                    }
                ],
                "audio": [
                    {
                        "id": "5684968",
                        "type": "primary",
                        "title": {
                            "$text": "Listen"
                        },
                        "duration": {
                            "$text": "0"
                        },
                        "format": {
                            "mp3": {
                                "type": "m3u",
                                "$text": "http://api.npr.org/m3u/15684968-2fd44e.m3u?orgId=715&topicId=1103&ft=3&f=15373040"
                            },
                            "wm": {
                                "$text": "http://www.npr.org/templates/dmg/dmg_wmref_em.php?id=5684968&type=1&mtype=WM&orgId=715&topicId=1103&ft=3&f=15373040"
                            },
                            "rm": {
                                "$text": "http://www.npr.org/templates/dmg/dmg_rpm.rpm?id=5684968&type=1&mtype=RM&orgId=715&topicId=1103&ft=3&f=15373040"
                            }
                        },
                        "rightsHolder": {
                            
                        },
                        "permissions": {
                            "download": {
                                "allow": "true"
                            },
                            "stream": {
                                "allow": "true"
                            },
                            "embed": {
                                "allow": "true"
                            }
                        }
                    },
                    {
                        "id": "5541330",
                        "type": "standard",
                        "title": {
                            "$text": "Listen"
                        },
                        "duration": {
                            "$text": "0"
                        },
                        "format": {
                            "mp3": {
                                "type": "m3u",
                                "$text": "http://api.npr.org/m3u/15541330-d70664.m3u?orgId=715&topicId=1103&ft=3&f=15373040"
                            },
                            "wm": {
                                "$text": "http://www.npr.org/templates/dmg/dmg_wmref_em.php?staticUrl=/npr/wc/2006/07/20060707_wc_01&mtype=WM&orgId=715&topicId=1103&ft=3&f=15373040"
                            },
                            "rm": {
                                "$text": "http://www.npr.org/templates/dmg/dmg_rpm.rpm?staticUrl=/npr/wc/2006/07/20060707_wc_01&mtype=RM&orgId=715&topicId=1103&ft=3&f=15373040"
                            }
                        },
                        "rightsHolder": {
                            
                        },
                        "permissions": {
                            "download": {
                                "allow": "true"
                            },
                            "stream": {
                                "allow": "true"
                            },
                            "embed": {
                                "allow": "true"
                            }
                        }
                    }
                ]
            },
            {
                "id": "5479731",
                "link": [
                    {
                        "type": "html",
                        "$text": "http://www.npr.org/templates/story/story.php?storyId=5479731&ft=3&f=15373040"
                    },
                    {
                        "type": "api",
                        "$text": "http://api.npr.org/query?id=5479731&apiKey=MDA0MzgzOTg2MDEyNTg5MjE2ODllNDk3MQ001"
                    }
                ],
                "title": {
                    "$text": "Sonic Youth: A 25-Year Experiment in Artful Noise"
                },
                "teaser": {
                    "$text": "Avant-garde rock band Sonic Youth is celebrating 25 years of making music together. In that quarter-century, its members have stayed true to their roots in the downtown New York art scene of the 1980s."
                },
                "show": [
                    {
                        "program": {
                            "id": "2",
                            "code": "ATC",
                            "$text": "All Things Considered"
                        },
                        "showDate": {
                            "$text": "Mon, 12 Jun 2006 16:00:00 -0400"
                        },
                        "segNum": {
                            "$text": "18"
                        }
                    }
                ],
                "audio": [
                    {
                        "id": "5480254",
                        "type": "primary",
                        "title": {
                            "$text": "Listen"
                        },
                        "duration": {
                            "$text": "0"
                        },
                        "format": {
                            "mp3": {
                                "type": "m3u",
                                "$text": "http://api.npr.org/m3u/15480254-ab30b5.m3u?orgId=1&topicId=1105&ft=3&f=15373040"
                            },
                            "wm": {
                                "$text": "http://www.npr.org/templates/dmg/dmg_wmref_em.php?id=5480254&type=1&mtype=WM&orgId=1&topicId=1105&ft=3&f=15373040"
                            },
                            "rm": {
                                "$text": "http://www.npr.org/templates/dmg/dmg_rpm.rpm?id=5480254&type=1&mtype=RM&orgId=1&topicId=1105&ft=3&f=15373040"
                            }
                        },
                        "rightsHolder": {
                            
                        },
                        "permissions": {
                            "download": {
                                "allow": "true"
                            },
                            "stream": {
                                "allow": "true"
                            },
                            "embed": {
                                "allow": "true"
                            }
                        }
                    }
                ]
            }
        ]
    }
}
=end

=begin
{"version": "0.93", "list": {"title": {"$text": "NPR: The Dirty Projectors"}, "teaser": {"$text": "The Dirty Projectors artist page: interviews, 
features and/or performances archived at NPR Music"}, "miniTeaser": {}, "link": {"type": "api", "$text": "http://api.npr.org/query/query?id=1573
5067&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}, "link": {"type": "html", "$text": "?ft=3&f=15735067"}, "story": [{"id": "106725467", "link"
: [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=106725467&ft=3&f=15735067"}, {"type": "api", "$text": "http:/
/api.npr.org/query?id=106725467&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}], "title": {"$text": "Dirty Projectors: Boundary-Pushing Rock"}}, 
{"id": "105586112", "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=105586112&ft=3&f=15735067"}, {"type
": "api", "$text": "http://api.npr.org/query?id=105586112&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}], "title": {"$text": "Dirty Projectors: 
Balancing Head And Heart"}}, {"id": "104578357", "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=1045783
57&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=104578357&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}], "title": {
"$text": "Exclusive First Listen: Dirty Projectors"}}, {"id": "99866524", "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/
story.php?storyId=99866524&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=99866524&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZ
jNhZQ001"}], "title": {"$text": "Brooklyn Brass, A Malian Masterpiece, Cabaret Pop, More"}}, {"id": "90245765", "link": [{"type": "html", "$text"
: "http://www.npr.org/templates/story/story.php?storyId=90245765&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=90245765
&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}], "title": {"$text": "BPP Jukebox: Dust Off the Dirty Projectors"}}, {"id": "17122446", "link": [{"
type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=17122446&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.
org/query?id=17122446&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}], "title": {"$text": "Dirty Projectors Let Black Flag Fly"}}, {"id": "15965475"
, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=15965475&ft=3&f=15735067"}, {"type": "api", "$text": "htt
p://api.npr.org/query?id=15965475&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}], "title": {"$text": "David Byrne, Beirut, Dirty Projectors"}}, {"i
d": "13969414", "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=13969414&ft=3&f=15735067"}, {"type": "api", 
"$text": "http://api.npr.org/query?id=13969414&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}], "title": {"$text": "Remaking a Punk Classic from Memo
ry"}}]}}
=end

=begin
{"version": "0.6", "list": {
    "title": {"$text": "Stories from NPR"},
    "teaser": {"$text": "Assorted stories from NPR"},
    "miniTeaser": { "$text": "Custom NPR News Feed API.  Visit http://api.npr.org/help.html for more information."},
    "story": [{ "id": "91280049",
                "type": "story",
                "active": "true",
                "link": [{"type": "html",
                          "$text": "http://api.npr.org/templates/story/story.php?storyId=91280049&f=91280049&ft=3"},
                          {"type": "api",
                           "$text": "http://api.npr.org/query?id=91280049"}],
                 "title": {"$text": "King and Holmes on Boxing"},
                 "subtitle": {},
                 "shortTitle": {},
                 "teaser": {"$text": "Scott Simon talks with boxing promoter Don King and boxing hall of famer Larry Holmes about their new video game, <em>Don King Presents: Prizefighter</em>, with story lines, in and out of the ring."},
                 "miniTeaser": {"$text": "Don King and Larry Holmes reminisce about their decades of involvement in the sport."},
                 "slug": {"$text": "Interviews"},
                 "thumbnail": {},
                 "storyDate": {"$text": "Sat, 07 Jun 2008 08:00:00 -0400"},
                 "pubDate": {"$text": "Sat, 07 Jun 2008 11:04:00 -0400"},
                 "lastModifiedDate": {"$text": "Sat, 07 Jun 2008 11:06:33 -0400"},
                 "show": [{"program": {"id": "7",
                                       "code": "WESAT",
                                       "$text": "Weekend Edition Saturday"},
                            "showDate": {"$text": "Sat, 07 Jun 2008 08:00:00 -0400"},
                            "segNum": {"$text": "21"}}],
                 "keywords": {},
                 "priorityKeywords": {},
                 "organization": [{"orgId": "1",
                                   "orgAbbr": "NPR",
                                   "name":{"$text": "National Public Radio"},
                                   "website": {"type": "Home Page",
                                               "$text": "http://www.npr.org/"}}],
                  "parent": [{"id": "1055",
                               "type": "topic",
                               "title": {"$text": "Sports"},
                               "link": [{"type": "html",
                                         "$text": "http://api.npr.org/templates/topics/topic.php?topicId=1055&f=91280049&ft=3"},
                                         {"type": "api",
                                          "$text": "http://api.npr.org/query?id=1055"}]
                                          },
                                          {"id": "1052",
                                           "type": "topic",
                                           "title": {"$text": "Fun & Games"},
                                           "link": [{"type": "html",
                                                     "$text": "http://api.npr.org/templates/topics/topic.php?topicId=1052&f=91280049&ft=3"},
                                                    {"type": "api",
                                                     "$text": "http://api.npr.org/query?id=1052"}]},
                                           {"id": "1051",
                                            "type": "topic",
                                            "title": {"$text": "Diversions"},
                                            "link": [{"type": "html",
                                                      "$text": "http://api.npr.org/templates/topics/topic.php?topicId=1051&f=91280049&ft=3"},
                                                     {"type": "api",
                                                      "$text": "http://api.npr.org/query?id=1051"}]
                                           },
                                           {"id": "1049",
                                            "type": "topic",
                                            "title": {"$text": "Digital Culture"},
                                            "link": [{"type": "html",
                                                      "$text": "http://api.npr.org/templates/topics/topic.php?topicId=1049&f=91280049&ft=3"},
                                                      {"type": "api",
                                                       "$text": "http://api.npr.org/query?id=1049"}]
                                            },
                                            {"id": "1022",
                                             "type": "topic",
                                             "title": {"$text": "Interviews"},
                                             "link": [{"type": "html",
                                                       "$text": "http://api.npr.org/templates/topics/topic.php?topicId=1022&f=91280049&ft=3"},
                                                      {"type": "api",
                                                       "$text": "http://api.npr.org/query?id=1022"}]
                                            },
                                            {"id": "1022",
                                             "type": "primaryTopic",
                                             "title": {"$text": "Interviews"},
                                             "link": [{"type": "html",
                                                       "$text": "http://api.npr.org/templates/topics/topic.php?topicId=1022&f=91280049&ft=3"},
                                                      {"type": "api", "$text": "http://api.npr.org/query?id=1022"}]
                                            },
                                            {"id": "1021",
                                             "type": "topic",
                                             "title": {"$text": "People & Places"},
                                             "link": [{"type": "html",
                                                       "$text": "http://api.npr.org/templates/topics/topic.php?topicId=1021&f=91280049&ft=3"},
                                                       {"type": "api",
                                                        "$text": "http://api.npr.org/query?id=1021"}]
                                                    }],
                                             "audio": [{"id": "91280057",
                                                        "primary": "true",
                                                        "title": {},
                                                        "duration": {"$text": "425"},
                                                        "format": {"mp3": {"$text": "http://api.npr.org/m3u/191280057-bd7a36.m3u&f=91280049&ft=3"},
                                                                   "wm": {"$text": "http://api.npr.org/templates/dmg/dmg_wmref_em.php?id=91280057&type=1&mtype=WM&f=91280049&ft=3"},
                                                                   "rm": {"$text": "http://api.npr.org/templates/dmg/dmg_rpm.rpm?id=91280057&type=1&mtype=RM&f=91280049&ft=3"}
                                                                   },
                                                        "rightsHolder": {}
                                                        }],
                                             "container": [{"id": "91281093",
                                                            "title": {"$text": "Related NPR Stories"},
                                                            "introText": {},
                                                            "link": {"refId": "91281096",
                                                                      "num": "1"},
                                                             "link": {"refId": "91281098",
                                                                       "num": "2"},
                                                             "link": {"refId": "91281100",
                                                                      "num": "3"},
                                                             "link": {"refId": "91281102",
                                                                      "num": "4"}
                                                             }],
                                             "relatedLink": [{"id": "91281096",
                                                              "type": "internal",
                                                              "caption": {"$text": "Mixed Martial Arts: A Knockout to Boxing?"},
                                                              "link": [{"type": "html",
                                                                         "$text": "http://api.npr.org/templates/story/story.php?storyId=89662907&f=91280049&ft=3"},
                                                                         {"type": "api",
                                                                          "$text": "http://api.npr.org/query?id=89662907"}],
                                                              "displayDate": {"$text": "true"}
                                                              },
                                                              {"id": "91281098",
                                                               "type": "internal",
                                                               "caption": {"$text": "A Conversation with Don King"},
                                                               "link": [{"type": "html",
                                                                         "$text": "http://api.npr.org/templates/story/story.php?storyId=5132610&f=91280049&ft=3"},
                                                                        {"type": "api",
                                                                         "$text": "http://api.npr.org/query?id=5132610"}],
                                                                "displayDate": {"$text": "true"}
                                                                },
                                                                {"id": "91281100",
                                                                 "type": "internal",
                                                                 "caption": {"$text": "Boxing: From Big-Time to Big Screen"},
                                                                 "link": [{"type": "html",
                                                                           "$text": "http://api.npr.org/templates/story/story.php?storyId=4696372&f=91280049&ft=3"},
                                                                          {"type": "api",
                                                                           "$text": "http://api.npr.org/query?id=4696372"}],
                                                                  "displayDate": {"$text": "true"}
                                                                  },
                                                                  {"id": "91281102",
                                                                   "type": "internal",
                                                                   "caption": {"$text": "Commentary: When Your Neighbor's a Champ"},
                                                                   "link": [{"type": "html",
                                                                             "$text": "http://api.npr.org/templates/story/story.php?storyId=1595889&f=91280049&ft=3"},
                                                                            {"type": "api",
                                                                             "$text": "http://api.npr.org/query?id=1595889"}],
                                                                    "displayDate": {"$text": "true"}
                                               }],
                                               "fullStory": {"$text": "<div class=\"slug\"><a href=\"/templates/topics/topic.php?topicId=1022\">Interviews</a></div><!-- END CLASS=\"SLUG\" --><h1>King and Holmes on Boxing</h1>                <div class=\"listenblock\">                    <p class=\"listentab\"><a href=\"javascript:NPR.Player.openPlayer(91280049, 91280057, null, NPR.Player.Action.PLAY_NOW, NPR.Player.Type.STORY, '0')\" class=\"listen\">Listen Now</a> <span class=\"duration\">[7 min 5 sec]</span> <a href=\"javascript:NPR.Player.openPlayer(91280049, 91280057, null, NPR.Player.Action.ADD_TO_PLAYLIST, NPR.Player.Type.STORY, '0')\" class=\"add\">add to playlist</a> </p>                </div><!-- START TOP RESOURCE POSITION --><!-- START INSET COLUMN --><!-- END INSET COLUMN --><!-- START STORY CONTENT --><p><span class=\"program\"><a href=\"/templates/rundowns/rundown.php?prgId=7\">Weekend Edition Saturday</a>,</span> <span class=\"date\">June 7, 2008 · </span> Scott Simon talks with boxing promoter Don King and boxing hall of famer Larry Holmes about their new video game, <em>Don King Presents: Prizefighter</em>, with story lines, in and out of the ring.</p><!-- END STORY CONTENT --><!-- STATIC PLAYLIST --><!-- START RELATED STORIES --><div class=\"dynamicbucket\"><div class=\"buckettop\"> </div><!-- END CLASS=\"BUCKETTOP\" --><h3>Related NPR Stories</h3><div class=\"bucketcontent\"><ul class=\"iconlinks\"><li><div class=\"date\">April 16, 2008</div><a href=\"/templates/story/story.php?storyId=89662907\" class=\"iconlink related\">Mixed Martial Arts: A Knockout to Boxing?</a></li><li><div class=\"date\">Jan. 6, 2006</div><a href=\"/templates/story/story.php?storyId=5132610\" class=\"iconlink related\">A Conversation with Don King</a></li><li><div class=\"date\">June 9, 2005</div><a href=\"/templates/story/story.php?storyId=4696372\" class=\"iconlink related\">Boxing: From Big-Time to Big Screen</a></li><li><div class=\"date\">Jan. 13, 2004</div><a href=\"/templates/story/story.php?storyId=1595889\" class=\"iconlink related\">Commentary: When Your Neighbor's a Champ</a></li></ul><div class=\"spacer\"> </div></div><!-- END CLASS=\"BUCKETCONTENT\" --><div class=\"bucketbottom\"> </div><!-- END CLASS=\"BUCKETBOTTOM\" --></div><!-- END RELATED STORIES -->Copyright 2008 NPR. To see more, visit <a href=\"http://www.npr.org/\">http://www.npr.org/</a>.<a src=\"http://media.npr.org/images/xanadu.gif?apiKey=MDAwMTIxNjMwMDEyMTQzMzUxNjAzOWRhYQ01\" />"},
                                               "layout": {"bottom":
                                                         {"container": {"refId": "91281093",
                                                                        "num": "1"}
                                                         }
                                                         }
                                               }]
    }
}
=end

=begin
{
  "version": "0.93", 
  "list": 
  {
    "title": {"$text": "NPR: The Dirty Projectors"}, 
    "teaser": {"$text": "The Dirty Projectors artist page: interviews, features and/or performances archived at NPR Music"}, 
    "miniTeaser": {}, 
    "link": 
    {
      "type": "api", 
      "$text": "http://api.npr.org/query/query?id=15735067&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"
    }, 
    "link": 
    {
      "type": "html", 
      "$text": "?ft=3&f=15735067"
    }, 
    "story": 
    [
      {
        "id": "106725467", 
        "link": 
        [
          {
            "type": "html", 
            "$text": "http://www.npr.org/templates/story/story.php?storyId=106725467&ft=3&f=15735067"
          }, 
          {"type": "api", "$text": "http://api.npr.org/query?id=106725467&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}
        ], 
        "title": 
        {
          "$text": "Dirty Projectors: Boundary-Pushing Rock"
        }
      }, 
      {
        "id": "105586112", 
        "link": 
        [
        {
          "type": "html", 
          "$text": "http://www.npr.org/templates/story/story.php?storyId=105586112&ft=3&f=15735067"
        }, 
        {
          "type": "api", 
          "$text": "http://api.npr.org/query?id=105586112&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"
        }
        ], 
        "title": {"$text": "Dirty Projectors: Balancing Head And Heart"}
        }, 
        {"id": "104578357", 
        "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=104578357&ft=3&f=15735067"}, 
        {"type": "api", "$text": "http://api.npr.org/query?id=104578357&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}], 
        "title": {"$text": "Exclusive First Listen: Dirty Projectors"}}, {"id": "99866524", "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=99866524&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=99866524&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}], "title": {"$text": "Brooklyn Brass, A Malian Masterpiece, Cabaret Pop, More"}}, {"id": "90245765", "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=90245765&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=90245765&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}], "title": {"$text": "BPP Jukebox: Dust Off the Dirty Projectors"}}, {"id": "17122446", "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=17122446&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=17122446&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}], "title": {"$text": "Dirty Projectors Let Black Flag Fly"}}, {"id": "15965475", "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=15965475&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=15965475&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}], "title": {"$text": "David Byrne, Beirut, Dirty Projectors"}}, {"id": "13969414", "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=13969414&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=13969414&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}], "title": {"$text": "Remaking a Punk Classic from Memory"}}]}}
=end

=begin
{
  "version": "0.93", 
  "list": 
  {
    "title": 
    {
      "$text": "NPR: The Dirty Projectors"
    }, 
    "teaser": 
    {
      "$text": "The Dirty Projectors artist page: interviews, features and/or performances archived at NPR Music"
    }, 
    "miniTeaser": 
    {
    
    }, 
    "link": 
    {
      "type": "api", 
      "$text": "http://api.npr.org/query/query?id=15735067&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"
    }, 
    "link": 
    {
      "type": "html", 
      "$text": "?ft=3&f=15735067"
    }, 
        "story": 
    [
      {
      "id": "106725467", 
      "link": 
      [
        {
          "type": "html", 
          "$text": "http://www.npr.org/templates/story/story.php?storyId=106725467&ft=3&f=15735067"
        }, 
        {
          "type": "api", 
          "$text": "http://api.npr.org/query?id=106725467&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"
        }
      ], 
      "title": 
      {
        "$text": "Dirty Projectors: Boundary-Pushing Rock"
      }, 
      "partnerId": {}, 
      "subtitle": {}, 
      "shortTitle": {}, 
      "teaser": 
      {
        "$text": "The avant-garde collective Dirty Projectors has been making waves with its new release, <em>Bitte Orca</em>. The album finds the band continuing its trademark experimentation, mixing traditional string arrangements with exploding drums, spidery guitars and boisterous keyboards."}, 
        "miniTeaser": 
        {
          "$text": "The avant-garde collective Dirty Projectors makes waves with the new album <em>Bitte Orca</em>."
        }, 
        "slug": 
        {
          "$text": "World Cafe"
        }, 
        "thumbnail": 
        {
          "medium": 
          {
            "$text": "http://media.npr.org/programs/wc/images/2009/07/dp75.jpg?t=1248631417"
          }
        }, 
        "storyDate": {"$text": "Mon, 10 Aug 2009 14:00:00 -0400"}, 
        "pubDate": {"$text": "Mon, 10 Aug 2009 09:39:00 -0400"}, 
        "lastModifiedDate": {"$text": "Mon, 10 Aug 2009 11:48:09 -0400"}, 
        "show": [{"program": {"id": "39", "code": "WC", "$text": "World Cafe"}, 
        "showDate": {"$text": "Mon, 10 Aug 2009 14:00:00 -0400"}, 
        "segNum": {"$text": "1"}}], "keywords": {}, "priorityKeywords": {}, 
        "organization": [{"orgId": "715", "orgAbbr": "WXPN", "name": {"$text": "WXPN-FM"}, "website": {"$text": "http://www.xpn.org/"}}],
        "parent": [{"id": "10001", "type": "genre", "title": {"$text": "Rock/Pop/Folk"}, 
          "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=10001&ft=3&f=15735067"}, 
            {"type": "api", "$text": "http://api.npr.org/query?id=10001&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, 
            {"id": "1103", "type": "primaryTopic", "title": {"$text": "Studio Sessions"}, 
          "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=1103&ft=3&f=15735067"}, 
            {"type": "api", "$text": "http://api.npr.org/query?id=1103&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, 
            {"id": "1103", "type": "topic", 
            "title": {"$text": "Studio Sessions"}, 
          "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=1103&ft=3&f=15735067"}, 
            {"type": "api", "$text": "http://api.npr.org/query?id=1103&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}], 
          "container": [{"id": "106725555", "title": {"$text": "Web Resources"}, 
          "introText": {}, "colSpan": {"$text": "1"}, "displayOptions": {"typeId": "2", "$text": "Display Both"}, 
          "link": {"refId": "106725559", "num": "1"}, 
          "link": {"refId": "106725563", "num": "2"}}, 
          {"id": "106725556", "title": {"$text": "Related NPR Stories"}, "introText": {}, "colSpan": {"$text": "1"}, 
          "displayOptions": {"typeId": "2", "$text": "Display Both"}, 
          "link": {"refId": "106725557", "num": "1"}, "link": {"refId": "106725561", "num": "2"}, "link": {"refId": "106725565", "num": "3"}}, 
          {"id": "106725596", "title": {"$text": "Set List"}, "introText": {}, "colSpan": {"$text": "1"}, "displayOptions": {"typeId": "2", "$text": "Display Both"}, 
          "listText": {"refId": "106725567", "num": "1"}}], "product": [{"id": "106725577", "type": "CD", "title": {"$text": "Bitte Orca"}, 
          "author": {"$text": "The Dirty Projectors"}, "upc": {"$text": "801390021718"}, "publisher": {"$text": "Domino"}, "publishYear": {"$text": "2009"}, 
          "purchaseLink": {}}], 
        "image": [{"id": "110948574", "type": "standard", "width": "75", 
          "src": "http://media.npr.org/programs/wc/images/2009/07/dp75.jpg?t=1248631417", "hasBorder": "false", "title": {"$text": "thumbnail"}, 
          "caption": {}, "link": {"url": ""}, "producer": {}, "provider": {"url": ""}, "copyright": {}}], 
          "relatedLink": [{"id": "106725559", "type": "external", 
          "caption": {"$text": "Dirty Projectors' Official Website"}, 
          "link": [{"type": "html", "$text": "http://www.dominorecordco.us/artists/dirty-projectors"}]}, 
          {"id": "106725563", "type": "external", "caption": {"$text": "Dirty Projectors' MySpace Page"}, 
          "link": [{"type": "html", "$text": "http://www.myspace.com/dirtyprojectors"}]}, 
          {"id": "106725557", "type": "internal", "caption": {"$text": "Dirty Projectors: Balancing Head And Heart"}, 
          "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=105586112&ft=3&f=15735067"}, 
          {"type": "api", "$text": "http://api.npr.org/query?id=105586112&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, 
          {"id": "106725561", "type": "internal", 
          "caption": {"$text": "Exclusive First Listen: Dirty Projectors"}, 
          "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=104578357&ft=3&f=15735067"}, 
          {"type": "api", "$text": "http://api.npr.org/query?id=104578357&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, 
          {"id": "106725565", "type": "internal", "caption": {"$text": "Remaking a Punk Classic from Memory"}, 
          "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=13969414&ft=3&f=15735067"}, 
          {"type": "api", "$text": "http://api.npr.org/query?id=13969414&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}], 
          "listText": [{"id": "106725567", "tag": "p", "paragraph": {"num": "1", "$text": "\"Remade Horizon\""}, "paragraph": {"num": "2", "$text": "\"Stillness Is the Move\""}, 
          "paragraph": {"num": "3", "$text": "\"Temecula Sunrise\""}, "paragraph": {"num": "4", "$text": "\"No Intention\""}}], "artist": [{"id": "111727305", "artistId": {"$text": "15735067"}, 
          "name": {"$text": "The Dirty Projectors"}}], 
          "text": [{"paragraph": {"num": "1", "$text": "The Brooklyn-based experimental rock group Dirty Projectors is the brainchild of frontman and chief songwriter Dave Longstreth, who released his own first album, The Graceful Fallen Mango, in 2001, before formally creating the band that launched his career. The group has pushed its sound with each new release, creating concept albums ranging from an opera about Don Henley to a re-imagining of Black Flag songs written from memory. With each new album, Longstreth's style and cast of musicians has changed."}, 
          "paragraph": {"num": "2", "$text": "Longstreth and company released Bitte Orca in June, earning rave reviews from critics and fans. The new album continues the band's trademark experimentation, mixing traditional string arrangements with exploding drums, spidery guitars and boisterous keyboards. The band's evolving songwriting has helped make BItte Orca its best work to date. In their World Cafe debut, The Dirty Projectors' members discuss their new album, while Longstreth talks about his personal relationship with music."}, 
          "paragraph": {"num": "3", "$text": "This story originally ran July 17, 2009.  Copyright 2009 WXPN-FM"}}], 
          "textWithHtml": [{"paragraph": {"num": "1", "$text": "The Brooklyn-based experimental rock group <a href=\"http://www.npr.org/templates/story/story.php?storyId=15735067\">Dirty Projectors</a> is the brainchild of frontman and chief songwriter Dave Longstreth, who released his own first album, <em>The Graceful Fallen Mango</em>, in 2001, before formally creating the band that launched his career. The group has pushed its sound with each new release, creating concept albums ranging from an opera about Don Henley to a re-imagining of Black Flag songs written from memory. With each new album, Longstreth's style and cast of musicians has changed."}, 
          "paragraph": {"num": "2", "$text": "Longstreth and company released <em>Bitte Orca</em> in June, earning rave reviews from critics and fans. The new album continues the band's trademark experimentation, mixing traditional string arrangements with exploding drums, spidery guitars and boisterous keyboards. The band's evolving songwriting has helped make <em>BItte Orca</em> its best work to date. In their World Cafe debut, The Dirty Projectors' members discuss their new album, while Longstreth talks about his personal relationship with music."}, "paragraph": {"num": "3", "$text": "<em>This story originally ran July 17, 2009.</em>  Copyright 2009 WXPN-FM. To see more, visit <a href=\"http://www.xpn.org/\">http://www.xpn.org/</a>.<img src=\"http://media.npr.org/images/xanadu.gif?apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001\" />"}}]}, {"id": "105586112", "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=105586112&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=105586112&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}], "title": {"$text": "Dirty Projectors: Balancing Head And Heart"}, "partnerId": {}, "subtitle": {}, "shortTitle": {}, "teaser": {"$text": "The experimental rock band based in New York draws on early vocal music, modern soul and other sources, defying categorization in the process. According to critic Will Hermes, the band's new album, <em>Bitte Orca,</em> is a breakthrough."}, "miniTeaser": {"$text": "<em>Bitte Orca</em> marks a breakthrough for the experimental New York rock band."}, "slug": {"$text": "Music Reviews"}, "storyDate": {"$text": "Thu, 18 Jun 2009 16:00:00 -0400"}, "pubDate": {"$text": "Thu, 18 Jun 2009 10:54:00 -0400"}, "lastModifiedDate": {"$text": "Fri, 19 Jun 2009 09:57:11 -0400"}, "show": [{"program": {"id": "2", "code": "ATC", "$text": "All Things Considered"}, "showDate": {"$text": "Thu, 18 Jun 2009 16:00:00 -0400"}, "segNum": {"$text": "7"}}], "keywords": {}, "priorityKeywords": {}, "organization": [{"orgId": "1", "orgAbbr": "NPR", "name": {"$text": "National Public Radio"}, "website": {"$text": "http://www.npr.org/"}}], "transcript": {"link": {"type": "api", "$text": "http://api.npr.org/transcript?id=105586112&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}}, "parent": [{"id": "10001", "type": "genre", "title": {"$text": "Rock/Pop/Folk"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=10001&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=10001&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "1104", "type": "primaryTopic", "slug": "true", "title": {"$text": "Music Reviews"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=1104&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=1104&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "1104", "type": "topic", "slug": "true", "title": {"$text": "Music Reviews"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=1104&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=1104&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}], "audio": [{"id": "105620608", "type": "primary", "title": {}, "duration": {"$text": "197"}, "format": {"mp3": {"type": "m3u", "$text": "http://api.npr.org/m3u/1105620608-962441.m3u?orgId=1&topicId=1104&ft=3&f=15735067"}, "wm": {"$text": "http://www.npr.org/templates/dmg/dmg_wmref_em.php?id=105620608&type=1&mtype=WM&orgId=1&topicId=1104&ft=3&f=15735067"}, "rm": {"$text": "http://www.npr.org/templates/dmg/dmg_rpm.rpm?id=105620608&type=1&mtype=RM&orgId=1&topicId=1104&ft=3&f=15735067"}}, "rightsHolder": {}, "permissions": {"download": {"allow": "true"}, "stream": {"allow": "true"}, "embed": {"allow": "true"}}}], "byline": [{"id": "105586319", "name": {"$text": "Will Hermes"}}], "container": [{"id": "105586110", "title": {"$text": "Web Resources"}, "introText": {}, "colSpan": {"$text": "1"}, "displayOptions": {"typeId": "2", "$text": "Display Both"}, "link": {"refId": "105586148", "num": "1"}}, {"id": "105586111", "title": {"$text": "Related NPR Stories"}, "introText": {}, "colSpan": {"$text": "1"}, "displayOptions": {"typeId": "2", "$text": "Display Both"}, "link": {"refId": "105586146", "num": "1"}, "link": {"refId": "105586151", "num": "2"}, "link": {"refId": "105652976", "num": "3"}, "link": {"refId": "105586154", "num": "4"}}, {"id": "105586177", "title": {"$text": "hear the music"}, "introText": {}, "colSpan": {"$text": "2"}, "displayOptions": {"typeId": "2", "$text": "Display Both"}}], "product": [{"id": "105586165", "type": "CD", "title": {"$text": "Bitte Orca"}, "author": {"$text": "The Dirty Projectors"}, "upc": {"$text": "801390021718"}, "publisher": {"$text": "Domino"}, "publishYear": {"$text": "2009"}, "purchaseLink": {}}], "relatedLink": [{"id": "105586148", "type": "external", "caption": {"$text": "Dirty Projector's MySpace Page"}, "link": [{"type": "html", "$text": "http://www.myspace.com/dirtyprojectors"}]}, {"id": "105586146", "type": "internal", "caption": {"$text": "Exclusive First Listen: Dirty Projectors"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=104578357&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=104578357&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "105586151", "type": "internal", "caption": {"$text": "SXSW 2009: Dirty Projectors"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=101414066&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=101414066&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "105652976", "type": "internal", "caption": {"$text": "Remaking a Punk Classic from Memory"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=13969414&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=13969414&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "105586154", "type": "internal", "caption": {"$text": "BPP Jukebox: Dust Off The Dirty Projectors"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=90245765&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=90245765&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}], "artist": [{"id": "105652900", "artistId": {"$text": "15735067"}, "name": {"$text": "The Dirty Projectors"}}], "song": [{"id": "104634641", "title": {"$text": "Cannibal Resource"}, "subtitle": {}, "artist": {"$text": "Dirty Projectors"}, "composer": {}, "discNum": {"$text": "1"}, "trackNum": {"$text": "1"}, "licensing": {}, "publisher": {}, "album": {"albumId": {"$text": "104578411"}, "albumTitle": {"$text": "Bitte Orca"}, "albumArtist": {"$text": "The Dirty Projectors"}, "albumYear": {"$text": "2009"}, "upc": {"$text": "801390021718"}, "label": {"$text": "Domino"}, "labelNum": {"$text": "217"}, "promoUrl": {}, "musicType": {"$text": "rock"}, "coverUrl": {"$text": "N/A"}}}, {"id": "105586169", "title": {"$text": "Temecula Sunrise"}, "subtitle": {}, "artist": {"$text": "Dirty Projectors"}, "composer": {}, "discNum": {"$text": "1"}, "trackNum": {"$text": "2"}, "licensing": {}, "publisher": {}, "album": {"albumId": {"$text": "104578411"}, "albumTitle": {"$text": "Bitte Orca"}, "albumArtist": {"$text": "The Dirty Projectors"}, "albumYear": {"$text": "2009"}, "upc": {"$text": "801390021718"}, "label": {"$text": "Domino"}, "labelNum": {"$text": "217"}, "promoUrl": {}, "musicType": {"$text": "rock"}, "coverUrl": {"$text": "N/A"}}}, {"id": "105586171", "title": {"$text": "Stillness Is The Move"}, "subtitle": {}, "artist": {"$text": "Dirty Projectors"}, "composer": {}, "discNum": {"$text": "1"}, "trackNum": {"$text": "4"}, "licensing": {}, "publisher": {}, "album": {"albumId": {"$text": "104578411"}, "albumTitle": {"$text": "Bitte Orca"}, "albumArtist": {"$text": "The Dirty Projectors"}, "albumYear": {"$text": "2009"}, "upc": {"$text": "801390021718"}, "label": {"$text": "Domino"}, "labelNum": {"$text": "217"}, "promoUrl": {}, "musicType": {"$text": "rock"}, "coverUrl": {"$text": "N/A"}}}], "text": [{"paragraph": {"num": "1", "$text": "It's been around 30 years &mdash; since the CBGB's era &mdash; since New York City has had a really vital rock scene. But they've sure got one now. Albums by Animal Collective and Grizzly Bear have already been flagged as two of this year's best. And I think another adventurous young band with Brooklyn roots, Dirty Projectors, has made a third."}, "paragraph": {"num": "2", "$text": "An experimental rock group with a shifting lineup, led by recent Yale graduate David Longstreth, Dirty Projectors can be playfully high-concept; the band has made a song cycle whose storyline somehow involves Eagles singer Don Henley and a highly abstracted remake of the LP Rise Above by the '80s punk rockers in Black Flag. But Bitte Orca &mdash; the band's latest release, so named because Dirty Projectors liked the sound of it &mdash; is more straightforward. It focuses on the mixed male and female voices of the band members. While parts are influenced by modern R&B, the arrangements are far different. The single \"Stillness Is the Move,\" for example, strikes me as a bit like Destiny's Child teaming up with Talking Heads."}, "paragraph": {"num": "3", "$text": "I've enjoyed other records by Dirty Projectors, but sometimes they seemed too eager to show off their smarts. The latest doesn't overthink &mdash; or, rather, overthinks just enough to balance head and heart. Recently, I saw the group at a show in New York City, and the mix of tart strangeness and melodic sugar in the vocals reminded me of how much depth the best pop musicians bring to their art. And it really made me hope that Dirty Projectors' members are in it for the long haul.  Copyright 2009 National Public Radio"}}], "textWithHtml": [{"paragraph": {"num": "1", "$text": "It's been around 30 years &mdash; since the CBGB's era &mdash; since New York City has had a really vital rock scene. But they've sure got one now. Albums by <a href=\"http://www.npr.org/templates/story/story.php?storyId=14993047\">Animal Collective</a> and <a href=\"http://www.npr.org/templates/story/story.php?storyId=14866307\">Grizzly Bear</a> have already been flagged as two of this year's best. And I think another adventurous young band with Brooklyn roots, <a href=\"http://www.npr.org/templates/story/story.php?storyId=15735067\">Dirty Projectors</a>, has made a third."}, "paragraph": {"num": "2", "$text": "An experimental rock group with a shifting lineup, led by recent Yale graduate David Longstreth, Dirty Projectors can be playfully high-concept; the band has made a song cycle whose storyline somehow involves Eagles singer Don Henley and a highly abstracted remake of the LP <em>Rise Above</em> by the '80s punk rockers in Black Flag. But <em>Bitte Orca</em> &mdash; the band's latest release, so named because Dirty Projectors liked the sound of it &mdash; is more straightforward. It focuses on the mixed male and female voices of the band members. While parts are influenced by modern R&B, the arrangements are far different. The single \"Stillness Is the Move,\" for example, strikes me as a bit like Destiny's Child teaming up with <a href=\"http://www.npr.org/templates/story/story.php?storyId=15321830\">Talking Heads</a>."}, "paragraph": {"num": "3", "$text": "I've enjoyed other records by Dirty Projectors, but sometimes they seemed too eager to show off their smarts. The latest doesn't overthink &mdash; or, rather, overthinks just enough to balance head and heart. Recently, I saw the group at a show in New York City, and the mix of tart strangeness and melodic sugar in the vocals reminded me of how much depth the best pop musicians bring to their art. And it really made me hope that Dirty Projectors' members are in it for the long haul.  Copyright 2009 National Public Radio. To see more, visit <a href=\"http://www.npr.org/\">http://www.npr.org/</a>.<img src=\"http://media.npr.org/images/xanadu.gif?apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001\" />"}}]}, {"id": "104578357", "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=104578357&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=104578357&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}], "title": {"$text": "Exclusive First Listen: Dirty Projectors"}, "partnerId": {}, "subtitle": {"$text": "Hear The Band's New Album, 'Bitte Orca,' In Its Entirety"}, "shortTitle": {}, "teaser": {"$text": "In what's already an unusually strong year for music, Dirty Projectors' <em>Bitte Orca</em> still stands out as one of 2009's most unusual and refreshingly unpredictable records. Hear the album in its idiosyncratic entirety."}, "miniTeaser": {"$text": "In <em>Bitte Orca</em>, Dave Longstreth and company have made a refreshingly unpredictable album."}, "slug": {"$text": "Exclusive First Listen"}, "storyDate": {"$text": "Sat, 30 May 2009 19:51:00 -0400"}, "pubDate": {"$text": "Sat, 30 May 2009 19:51:00 -0400"}, "lastModifiedDate": {"$text": "Mon, 27 Jul 2009 13:55:29 -0400"}, "keywords": {}, "priorityKeywords": {}, "organization": [{"orgId": "1", "orgAbbr": "NPR", "name": {"$text": "National Public Radio"}, "website": {"$text": "http://www.npr.org/"}}], "parent": [{"id": "98679384", "type": "series", "slug": "true", "title": {"$text": "Exclusive First Listen"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=98679384&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=98679384&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "10001", "type": "genre", "title": {"$text": "Rock/Pop/Folk"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=10001&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=10001&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "1108", "type": "topic", "title": {"$text": "Discover Songs"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=1108&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=1108&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "1108", "type": "primaryTopic", "title": {"$text": "Discover Songs"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=1108&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=1108&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}], "byline": [{"id": "104637483", "name": {"personId": "91465290", "$text": "Robin Hilton"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=91465290&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=91465290&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}], "container": [{"id": "104634693", "title": {}, "introText": {}, "colSpan": {"$text": "1"}, "displayOptions": {"typeId": "2", "$text": "Display Both"}, "listText": {"refId": "104578401", "num": "1"}, "listText": {"refId": "104578406", "num": "2"}, "listText": {"refId": "104933526", "num": "3"}}], "product": [{"id": "104636192", "type": "CD", "title": {"$text": "Bitte Orca"}, "author": {"$text": "The Dirty Projectors"}, "upc": {"$text": "801390021718"}, "publisher": {"$text": "Domino"}, "publishYear": {"$text": "2009"}, "purchaseLink": {}}, {"id": "104636175", "type": "CD", "title": {"$text": "Bitte Orca"}, "author": {"$text": "The Dirty Projectors"}, "upc": {"$text": "801390021718"}, "publisher": {"$text": "Domino"}, "publishYear": {"$text": "2009"}, "purchaseLink": {}}, {"id": "104636177", "type": "CD", "title": {"$text": "Bitte Orca"}, "author": {"$text": "The Dirty Projectors"}, "upc": {"$text": "801390021718"}, "publisher": {"$text": "Domino"}, "publishYear": {"$text": "2009"}, "purchaseLink": {}}, {"id": "104636179", "type": "CD", "title": {"$text": "Bitte Orca"}, "author": {"$text": "The Dirty Projectors"}, "upc": {"$text": "801390021718"}, "publisher": {"$text": "Domino"}, "publishYear": {"$text": "2009"}, "purchaseLink": {}}, {"id": "104636181", "type": "CD", "title": {"$text": "Bitte Orca"}, "author": {"$text": "The Dirty Projectors"}, "upc": {"$text": "801390021718"}, "publisher": {"$text": "Domino"}, "publishYear": {"$text": "2009"}, "purchaseLink": {}}, {"id": "104636183", "type": "CD", "title": {"$text": "Bitte Orca"}, "author": {"$text": "The Dirty Projectors"}, "upc": {"$text": "801390021718"}, "publisher": {"$text": "Domino"}, "publishYear": {"$text": "2009"}, "purchaseLink": {}}, {"id": "104636185", "type": "CD", "title": {"$text": "Bitte Orca"}, "author": {"$text": "The Dirty Projectors"}, "upc": {"$text": "801390021718"}, "publisher": {"$text": "Domino"}, "publishYear": {"$text": "2009"}, "purchaseLink": {}}, {"id": "104636187", "type": "CD", "title": {"$text": "Bitte Orca"}, "author": {"$text": "The Dirty Projectors"}, "upc": {"$text": "801390021718"}, "publisher": {"$text": "Domino"}, "publishYear": {"$text": "2009"}, "purchaseLink": {}}, {"id": "104636189", "type": "CD", "title": {"$text": "Bitte Orca"}, "author": {"$text": "The Dirty Projectors"}, "upc": {"$text": "801390021718"}, "publisher": {"$text": "Domino"}, "publishYear": {"$text": "2009"}, "purchaseLink": {}}, {"id": "104578399", "type": "CD", "title": {"$text": "Bitte Orca"}, "author": {"$text": "The Dirty Projectors"}, "upc": {"$text": "801390021718"}, "publisher": {"$text": "Domino"}, "publishYear": {"$text": "2009"}, "purchaseLink": {}}], "image": [{"id": "104636173", "type": "standard", "width": "200", "src": "http://media.npr.org/music/firstlisten09/dirtyprojectors/bitteorca_200.jpg?t=1248635984", "hasBorder": "false", "title": {"$text": "Bitte Orca cover"}, "caption": {}, "link": {"url": ""}, "producer": {}, "provider": {"url": ""}, "copyright": {}}], "listText": [{"id": "104578401", "tag": "p", "paragraph": {"num": "1", "$text": "<a href=\"http://www.npr.org/templates/story/story.php?storyId=98679384\">More Exclusive First Listens</a>"}}, {"id": "104578406", "tag": "p", "paragraph": {"num": "1", "$text": "<a href=\"http://www.npr.org/templates/story/story.php?storyId=101414066\">SXSW 2009: Dirty Projectors In Concert</a>"}}, {"id": "104933526", "tag": "p", "paragraph": {"num": "1", "$text": "<a href=\"http://www.npr.org/templates/story/story.php?storyId=104655046\">Dirty Projectors and David Byrne perform at the Dark Was The Night concert</a>"}}, {"id": "105233382", "tag": "p", "paragraph": {"num": "1", "$text": "<em>Audio for this feature is no longer available.  The album was released on June 9, 2009.</em>"}}], "artist": [{"id": "104578413", "artistId": {"$text": "15735067"}, "name": {"$text": "The Dirty Projectors"}}], "song": [{"id": "104634641", "title": {"$text": "Cannibal Resource"}, "subtitle": {}, "artist": {"$text": "Dirty Projectors"}, "composer": {}, "discNum": {"$text": "1"}, "trackNum": {"$text": "1"}, "licensing": {}, "publisher": {}, "album": {"albumId": {"$text": "104578411"}, "albumTitle": {"$text": "Bitte Orca"}, "albumArtist": {"$text": "The Dirty Projectors"}, "albumYear": {"$text": "2009"}, "upc": {"$text": "801390021718"}, "label": {"$text": "Domino"}, "labelNum": {"$text": "217"}, "promoUrl": {}, "musicType": {"$text": "rock"}, "coverUrl": {"$text": "N/A"}}}, {"id": "104634642", "title": {"$text": "Temecula Sunrise"}, "subtitle": {}, "artist": {"$text": "Dirty Projectors"}, "composer": {}, "discNum": {"$text": "1"}, "trackNum": {"$text": "2"}, "licensing": {}, "publisher": {}, "album": {"albumId": {"$text": "104578411"}, "albumTitle": {"$text": "Bitte Orca"}, "albumArtist": {"$text": "The Dirty Projectors"}, "albumYear": {"$text": "2009"}, "upc": {"$text": "801390021718"}, "label": {"$text": "Domino"}, "labelNum": {"$text": "217"}, "promoUrl": {}, "musicType": {"$text": "rock"}, "coverUrl": {"$text": "N/A"}}}, {"id": "104634643", "title": {"$text": "The Bride"}, "subtitle": {}, "artist": {"$text": "Dirty Projectors"}, "composer": {}, "discNum": {"$text": "1"}, "trackNum": {"$text": "3"}, "licensing": {}, "publisher": {}, "album": {"albumId": {"$text": "104578411"}, "albumTitle": {"$text": "Bitte Orca"}, "albumArtist": {"$text": "The Dirty Projectors"}, "albumYear": {"$text": "2009"}, "upc": {"$text": "801390021718"}, "label": {"$text": "Domino"}, "labelNum": {"$text": "217"}, "promoUrl": {}, "musicType": {"$text": "rock"}, "coverUrl": {"$text": "N/A"}}}, {"id": "104634644", "title": {"$text": "Stillness Is The Move"}, "subtitle": {}, "artist": {"$text": "Dirty Projectors"}, "composer": {}, "discNum": {"$text": "1"}, "trackNum": {"$text": "4"}, "licensing": {}, "publisher": {}, "album": {"albumId": {"$text": "104578411"}, "albumTitle": {"$text": "Bitte Orca"}, "albumArtist": {"$text": "The Dirty Projectors"}, "albumYear": {"$text": "2009"}, "upc": {"$text": "801390021718"}, "label": {"$text": "Domino"}, "labelNum": {"$text": "217"}, "promoUrl": {}, "musicType": {"$text": "rock"}, "coverUrl": {"$text": "N/A"}}}, {"id": "104634645", "title": {"$text": "Two Doves"}, "subtitle": {}, "artist": {"$text": "Dirty Projectors"}, "composer": {}, "discNum": {"$text": "1"}, "trackNum": {"$text": "5"}, "licensing": {}, "publisher": {}, "album": {"albumId": {"$text": "104578411"}, "albumTitle": {"$text": "Bitte Orca"}, "albumArtist": {"$text": "The Dirty Projectors"}, "albumYear": {"$text": "2009"}, "upc": {"$text": "801390021718"}, "label": {"$text": "Domino"}, "labelNum": {"$text": "217"}, "promoUrl": {}, "musicType": {"$text": "rock"}, "coverUrl": {"$text": "N/A"}}}, {"id": "104634646", "title": {"$text": "Useful Chamber"}, "subtitle": {}, "artist": {"$text": "Dirty Projectors"}, "composer": {}, "discNum": {"$text": "1"}, "trackNum": {"$text": "6"}, "licensing": {}, "publisher": {}, "album": {"albumId": {"$text": "104578411"}, "albumTitle": {"$text": "Bitte Orca"}, "albumArtist": {"$text": "The Dirty Projectors"}, "albumYear": {"$text": "2009"}, "upc": {"$text": "801390021718"}, "label": {"$text": "Domino"}, "labelNum": {"$text": "217"}, "promoUrl": {}, "musicType": {"$text": "rock"}, "coverUrl": {"$text": "N/A"}}}, {"id": "104634647", "title": {"$text": "No Intention"}, "subtitle": {}, "artist": {"$text": "Dirty Projectors"}, "composer": {}, "discNum": {"$text": "1"}, "trackNum": {"$text": "7"}, "licensing": {}, "publisher": {}, "album": {"albumId": {"$text": "104578411"}, "albumTitle": {"$text": "Bitte Orca"}, "albumArtist": {"$text": "The Dirty Projectors"}, "albumYear": {"$text": "2009"}, "upc": {"$text": "801390021718"}, "label": {"$text": "Domino"}, "labelNum": {"$text": "217"}, "promoUrl": {}, "musicType": {"$text": "rock"}, "coverUrl": {"$text": "N/A"}}}, {"id": "104634648", "title": {"$text": "Remade Horizon"}, "subtitle": {}, "artist": {"$text": "Dirty Projectors"}, "composer": {}, "discNum": {"$text": "1"}, "trackNum": {"$text": "8"}, "licensing": {}, "publisher": {}, "album": {"albumId": {"$text": "104578411"}, "albumTitle": {"$text": "Bitte Orca"}, "albumArtist": {"$text": "The Dirty Projectors"}, "albumYear": {"$text": "2009"}, "upc": {"$text": "801390021718"}, "label": {"$text": "Domino"}, "labelNum": {"$text": "217"}, "promoUrl": {}, "musicType": {"$text": "rock"}, "coverUrl": {"$text": "N/A"}}}, {"id": "104634649", "title": {"$text": "Fluorescent Half Dome"}, "subtitle": {}, "artist": {"$text": "Dirty Projectors"}, "composer": {}, "discNum": {"$text": "1"}, "trackNum": {"$text": "9"}, "licensing": {}, "publisher": {}, "album": {"albumId": {"$text": "104578411"}, "albumTitle": {"$text": "Bitte Orca"}, "albumArtist": {"$text": "The Dirty Projectors"}, "albumYear": {"$text": "2009"}, "upc": {"$text": "801390021718"}, "label": {"$text": "Domino"}, "labelNum": {"$text": "217"}, "promoUrl": {}, "musicType": {"$text": "rock"}, "coverUrl": {"$text": "N/A"}}}], "text": [{"paragraph": {"num": "1", "$text": "It's been an unusually strong year for music, and we're not even halfway through it. New albums from Animal Collective, The Decemberists, M. Ward, Danger Mouse and Sparklehorse, and many other artists have already made 2009 an extraordinarily memorable year. In such a crowded field of talent, Bitte Orca &mdash; the new album from Dirty Projectors &mdash; still stands out as one of the year's most unusual and refreshingly unpredictable records. Listen to the entire album for a week before its release, as part of our Exclusive First Listen series."}, "paragraph": {"num": "2", "$text": "Bitte Orca is the fifth full-length studio album from Dirty Projectors, and while it takes a lot of unexpected turns into surreal sonic territory, it's probably the band's most accessible work so far. It's also its most fully realized, mixing strange and unpredictable song structures with moments of bracing beauty. Far from conventional pop music, Bitte Orca has nevertheless spawned the sort of pre-release buzz reserved for budding stars."}, "paragraph": {"num": "3", "$text": "The members of Dirty Projectors have a well-earned reputation for dismantling standard melodic forms and chord structures and rearranging the elements until they no longer resemble the kinds of songs most people are used to hearing. The result is idiosyncratic and complex, but it's also the sort of musical thrill ride that some listeners won't enjoy. Still, love it or hate it, it's hard not to be impressed with what Dirty Projectors' members have accomplished. Bitte Orca is awe-inspiringly executed and marked by sparkling imagination."}, "paragraph": {"num": "4", "$text": "Dave Longstreth formed Dirty Projectors in 2002, and the group now also counts Angel Deradoorian, Amber Coffman and Brian McComber as principal members.  Copyright 2009 National Public Radio"}}], "textWithHtml": [{"paragraph": {"num": "1", "$text": "It's been an unusually strong year for music, and we're not even halfway through it. New albums from <a href=\"/templates/story/story.php?storyId=14993047\">Animal Collective</a>, <a href=\"/templates/story/story.php?storyId=15189635\">The Decemberists</a>, <a href=\"/templates/story/story.php?storyId=15328262\">M. Ward</a>, <a href=\"/templates/story/story.php?storyId=15359912\">Danger Mouse</a> and <a href=\"/templates/story/story.php?storyId=15397817\">Sparklehorse</a>, and many other artists have already made 2009 an extraordinarily memorable year. In such a crowded field of talent, <em>Bitte Orca</em> &mdash; the new album from <a href=\"/templates/story/story.php?storyId=15735067\">Dirty Projectors</a> &mdash; still stands out as one of the year's most unusual and refreshingly unpredictable records. Listen to the entire album for a week before its release, as part of our <a href=\"/templates/story/story.php?storyId=98679384\">Exclusive First Listen</a> series."}, "paragraph": {"num": "2", "$text": "<em>Bitte Orca</em> is the fifth full-length studio album from Dirty Projectors, and while it takes a lot of unexpected turns into surreal sonic territory, it's probably the band's most accessible work so far. It's also its most fully realized, mixing strange and unpredictable song structures with moments of bracing beauty. Far from conventional pop music, <em>Bitte Orca</em> has nevertheless spawned the sort of pre-release buzz reserved for budding stars."}, "paragraph": {"num": "3", "$text": "The members of Dirty Projectors have a well-earned reputation for dismantling standard melodic forms and chord structures and rearranging the elements until they no longer resemble the kinds of songs most people are used to hearing. The result is idiosyncratic and complex, but it's also the sort of musical thrill ride that some listeners won't enjoy. Still, love it or hate it, it's hard not to be impressed with what Dirty Projectors' members have accomplished. <em>Bitte Orca</em> is awe-inspiringly executed and marked by sparkling imagination."}, "paragraph": {"num": "4", "$text": "Dave Longstreth formed Dirty Projectors in 2002, and the group now also counts Angel Deradoorian, Amber Coffman and Brian McComber as principal members.  Copyright 2009 National Public Radio. To see more, visit <a href=\"http://www.npr.org/\">http://www.npr.org/</a>.<img src=\"http://media.npr.org/images/xanadu.gif?apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001\" />"}}]}, {"id": "99866524", "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=99866524&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=99866524&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}], "title": {"$text": "Brooklyn Brass, A Malian Masterpiece, Cabaret Pop, More"}, "partnerId": {}, "subtitle": {}, "shortTitle": {}, "teaser": {"$text": "The New York-based band Beirut travels to Mexico for its latest album: a brassy, adventurous double EP called <em>March of Zapotec</em>.  It won't be released until the end of February, but you can hear a sneak preview here with the song, \"The Shrew.\"  Also on this edition of <em>All Songs Considered</em>:  an ambitious debut release from the seven-piece, Nashville-based ensemble Darla Farmer; a collaboration between David Byrne and the Dirty Projectors, as part of a new album to promote AIDS awareness; a moody, gorgeous new album from Mali's Rokia Traore; new music from the seemingly tortured Antony and the Johnsons; a solo release from AC Newman of the New Pornographers; and Norwegian punk-pop singer Ida Maria."}, "miniTeaser": {"$text": "From <em>All Songs Considered</em>: David Byrne, AC Newman, Beirut, Rokia Traore, and more."}, "slug": {"$text": "All Songs Considered"}, "thumbnail": {"medium": {"$text": "http://media.npr.org/programs/asc/archives/20090126/traorecvr.jpg?t=1248630458"}}, "storyDate": {"$text": "Mon, 26 Jan 2009 12:00:00 -0500"}, "pubDate": {"$text": "Mon, 26 Jan 2009 11:11:00 -0500"}, "lastModifiedDate": {"$text": "Mon, 27 Jul 2009 13:59:56 -0400"}, "show": [{"program": {"id": "37", "code": "ASC", "$text": "All Songs Considered"}, "showDate": {"$text": "Mon, 26 Jan 2009 12:00:00 -0500"}, "segNum": {"$text": "1"}}], "keywords": {}, "priorityKeywords": {}, "organization": [{"orgId": "1", "orgAbbr": "NPR", "name": {"$text": "National Public Radio"}, "website": {"$text": "http://www.npr.org/"}}], "parent": [{"id": "10004", "type": "genre", "title": {"$text": "World"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=10004&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=10004&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "10001", "type": "genre", "title": {"$text": "Rock/Pop/Folk"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=10001&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=10001&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "1108", "type": "primaryTopic", "title": {"$text": "Discover Songs"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=1108&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=1108&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "1108", "type": "topic", "title": {"$text": "Discover Songs"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=1108&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=1108&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "1104", "type": "topic", "title": {"$text": "Music Reviews"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=1104&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=1104&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}], "audio": [{"id": "99866575", "type": "primary", "title": {}, "duration": {"$text": "0"}, "format": {"mp3": {"type": "m3u", "$text": "http://api.npr.org/m3u/199866575-ff9621.m3u?orgId=1&topicId=1108&ft=3&f=15735067"}, "wm": {"$text": "http://www.npr.org/templates/dmg/dmg_wmref_em.php?id=99866575&type=1&mtype=WM&orgId=1&topicId=1108&ft=3&f=15735067"}, "rm": {"$text": "http://www.npr.org/templates/dmg/dmg_rpm.rpm?id=99866575&type=1&mtype=RM&orgId=1&topicId=1108&ft=3&f=15735067"}}, "rightsHolder": {}, "permissions": {"download": {"allow": "true"}, "stream": {"allow": "true"}, "embed": {"allow": "true"}}}], "product": [{"id": "99868412", "type": "CD", "title": {"$text": "March of the Zapotec"}, "author": {"$text": "Beirut"}, "upc": {"$text": "600197220115"}, "publisher": {"$text": "Pompeii/Ba Da Bing!"}, "publishYear": {"$text": "2009"}, "purchaseLink": {}}, {"id": "99868565", "type": "CD", "title": {"$text": "Rewiring Electric Forest"}, "author": {"$text": "Darla Farmer"}, "upc": {"$text": "616892945925"}, "publisher": {"$text": "Paper Garden"}, "publishYear": {"$text": "2009"}, "purchaseLink": {}}, {"id": "99868567", "type": "CD", "title": {"$text": "Dark Was the Night [4AD]"}, "author": {"$text": "Dirty Projectors and David Byrne"}, "upc": {"$text": "652637283525"}, "publisher": {"$text": "4AD"}, "publishYear": {"$text": "2009"}, "purchaseLink": {}}, {"id": "99868828", "type": "CD", "title": {"$text": "TchamantchÃ©"}, "author": {"$text": "Rokia TraorÃ©"}, "upc": {"$text": "075597983265"}, "publisher": {"$text": "Nonesuch"}, "publishYear": {"$text": "2008"}, "purchaseLink": {}}, {"id": "99869030", "type": "CD", "title": {"$text": "Crying Light"}, "author": {"$text": "Antony and the Johnsons"}, "upc": {"$text": "656605019413"}, "publisher": {"$text": "Secretly Canadian"}, "publishYear": {"$text": "2009"}, "purchaseLink": {}}, {"id": "99869574", "type": "CD", "title": {"$text": "Get Guilty"}, "author": {"$text": "A.C. Newman"}, "upc": {"$text": "0823566057420"}, "publisher": {"$text": "Broken Horse"}, "publishYear": {"$text": "2009"}, "purchaseLink": {}}], "image": [{"id": "99868410", "type": "standard", "width": "75", "src": "http://media.npr.org/programs/asc/archives/20090126/beirutcvr.jpg?t=1248630458", "hasBorder": "false", "title": {"$text": "cover for beirut"}, "caption": {}, "link": {"url": ""}, "producer": {}, "provider": {"url": ""}, "copyright": {}}, {"id": "99868561", "type": "standard", "width": "75", "src": "http://media.npr.org/programs/asc/archives/20090126/farmercvr.jpg?t=1248630458", "hasBorder": "false", "title": {"$text": "cover for darla farmer"}, "caption": {}, "link": {"url": ""}, "producer": {}, "provider": {"url": ""}, "copyright": {}}, {"id": "99868563", "type": "standard", "width": "75", "src": "http://media.npr.org/programs/asc/archives/20090126/byrnecvr.jpg?t=1248630458", "hasBorder": "false", "title": {"$text": "cover for dark was the night"}, "caption": {}, "link": {"url": ""}, "producer": {}, "provider": {"url": ""}, "copyright": {}}, {"id": "99868825", "type": "standard", "width": "75", "src": "http://media.npr.org/programs/asc/archives/20090126/traorecvr.jpg?t=1248630458", "hasBorder": "false", "title": {"$text": "cover for rokia traore"}, "caption": {}, "link": {"url": ""}, "producer": {}, "provider": {"url": ""}, "copyright": {}}, {"id": "99869028", "type": "standard", "width": "75", "src": "http://media.npr.org/programs/asc/archives/20090126/johnsonscvr.jpg?t=1248630458", "hasBorder": "false", "title": {"$text": "cover for antony and the johnsons"}, "caption": {}, "link": {"url": ""}, "producer": {}, "provider": {"url": ""}, "copyright": {}}, {"id": "99869570", "type": "standard", "width": "75", "src": "http://media.npr.org/programs/asc/archives/20090126/newmancvr.jpg?t=1248630458", "hasBorder": "false", "title": {"$text": "cover for a.c. newman"}, "caption": {}, "link": {"url": ""}, "producer": {}, "provider": {"url": ""}, "copyright": {}}, {"id": "99869572", "type": "standard", "width": "75", "src": "http://media.npr.org/programs/asc/archives/20090126/mariacvr.jpg?t=1248630458", "hasBorder": "false", "title": {"$text": "cover for ida maria"}, "caption": {}, "link": {"url": ""}, "producer": {}, "provider": {"url": ""}, "copyright": {}}, {"id": "99866701", "type": "primary", "width": "200", "src": "http://media.npr.org/programs/asc/archives/20090126/collage300.jpg?t=1248630458&s=12", "hasBorder": "false", "title": {"$text": "collage 300"}, "caption": {}, "link": {"url": ""}, "producer": {}, "provider": {"url": ""}, "copyright": {}}, {"id": "99866703", "type": "standard", "width": "200", "src": "http://media.npr.org/programs/asc/archives/20090126/collage200.jpg?t=1248630458", "hasBorder": "false", "title": {"$text": "collage 200"}, "caption": {}, "link": {"url": ""}, "producer": {}, "provider": {"url": ""}, "copyright": {}}, {"id": "110937634", "type": "standard", "width": "75", "src": "http://media.npr.org/programs/asc/archives/20090126/traorecvr.jpg?t=1248630458", "hasBorder": "false", "title": {"$text": "thumbnail"}, "caption": {}, "link": {"url": ""}, "producer": {}, "provider": {"url": ""}, "copyright": {}}], "artist": [{"id": "99869965", "artistId": {"$text": "15148770"}, "name": {"$text": "Beirut"}}, {"id": "99869968", "artistId": {"$text": "14995698"}, "name": {"$text": "Rokia TraorÃ©"}}, {"id": "99869971", "artistId": {"$text": "15320822"}, "name": {"$text": "David Byrne"}}, {"id": "99869974", "artistId": {"$text": "15735067"}, "name": {"$text": "The Dirty Projectors"}}, {"id": "99869977", "artistId": {"$text": "98386884"}, "name": {"$text": "Ida Maria"}}, {"id": "99869980", "artistId": {"$text": "16149139"}, "name": {"$text": "A.C. Newman"}}, {"id": "99869983", "artistId": {"$text": "15239231"}, "name": {"$text": "Antony and the Johnsons"}}], "song": [{"id": "99865285", "title": {"$text": "The Shrew"}, "subtitle": {}, "artist": {"$text": "Beirut"}, "composer": {}, "discNum": {"$text": "1"}, "trackNum": {"$text": "6"}, "licensing": {}, "publisher": {}, "album": {"albumId": {"$text": "99865284"}, "albumTitle": {"$text": "March of the Zapotec"}, "albumArtist": {"$text": "Beirut"}, "albumYear": {"$text": "2009"}, "upc": {"$text": "600197220115"}, "label": {"$text": "Pompeii/Ba Da Bing!"}, "labelNum": {"$text": "5"}, "promoUrl": {}, "musicType": {"$text": "rock"}, "coverUrl": {"$text": "N/A"}}}, {"id": "99865317", "title": {"$text": "The Strangler Fig"}, "subtitle": {}, "artist": {"$text": "Darla Farmer"}, "composer": {}, "discNum": {"$text": "1"}, "trackNum": {"$text": "5"}, "licensing": {}, "publisher": {}, "album": {"albumId": {"$text": "99865316"}, "albumTitle": {"$text": "Rewiring Electric Forest"}, "albumArtist": {"$text": "Darla Farmer"}, "albumYear": {"$text": "2009"}, "upc": {"$text": "616892945925"}, "label": {"$text": "Paper Garden"}, "labelNum": {"$text": "29459"}, "promoUrl": {}, "musicType": {"$text": "rock"}, "coverUrl": {"$text": "N/A"}}}, {"id": "99865321", "title": {"$text": "Knotty Pine"}, "subtitle": {}, "artist": {"$text": "David Byrne & The Dirty Projectors"}, "composer": {}, "discNum": {"$text": "1"}, "trackNum": {"$text": "1"}, "licensing": {}, "publisher": {}, "album": {"albumId": {"$text": "99865320"}, "albumTitle": {"$text": "Dark Was the Night [4AD]"}, "albumArtist": {"$text": "Dirty Projectors and David Byrne"}, "albumYear": {"$text": "2009"}, "upc": {"$text": "652637283525"}, "label": {"$text": "4AD"}, "labelNum": {"$text": "72835"}, "promoUrl": {}, "musicType": {"$text": "rock"}, "coverUrl": {"$text": "N/A"}}}, {"id": "99865366", "title": {"$text": "Dounia"}, "subtitle": {}, "artist": {"$text": "Rokia TraorÃ©"}, "composer": {"$text": "Traore"}, "discNum": {"$text": "1"}, "trackNum": {"$text": "1"}, "licensing": {}, "publisher": {"$text": "Traore"}, "album": {"albumId": {"$text": "99865365"}, "albumTitle": {"$text": "TchamantchÃ©"}, "albumArtist": {"$text": "Rokia TraorÃ©"}, "albumYear": {"$text": "2008"}, "upc": {"$text": "075597983265"}, "label": {"$text": "Nonesuch"}, "labelNum": {"$text": "517818"}, "promoUrl": {}, "musicType": {"$text": "world"}, "coverUrl": {"$text": "N/A"}}}, {"id": "99865388", "title": {"$text": "Everglade"}, "subtitle": {}, "artist": {"$text": "Antony and the Johnsons"}, "composer": {"$text": "Antony"}, "discNum": {"$text": "1"}, "trackNum": {"$text": "10"}, "licensing": {}, "publisher": {"$text": "Antony"}, "album": {"albumId": {"$text": "99865378"}, "albumTitle": {"$text": "Crying Light"}, "albumArtist": {"$text": "Antony and the Johnsons"}, "albumYear": {"$text": "2009"}, "upc": {"$text": "656605019413"}, "label": {"$text": "Secretly Canadian"}, "labelNum": {"$text": "50194"}, "promoUrl": {}, "musicType": {"$text": "rock"}, "coverUrl": {"$text": "N/A"}}}, {"id": "99487781", "title": {"$text": "Heartbreak Rides"}, "subtitle": {}, "artist": {"$text": "A.C. Newman"}, "composer": {"$text": "Newman"}, "discNum": {"$text": "1"}, "trackNum": {"$text": "2"}, "licensing": {}, "publisher": {"$text": "Newman"}, "album": {"albumId": {"$text": "99487770"}, "albumTitle": {"$text": "Get Guilty"}, "albumArtist": {"$text": "A.C. Newman"}, "albumYear": {"$text": "2009"}, "upc": {"$text": "0823566057420"}, "label": {"$text": "Broken Horse"}, "labelNum": {"$text": "016"}, "promoUrl": {}, "musicType": {"$text": "rock"}, "coverUrl": {"$text": "N/A"}}}, {"id": "98387159", "title": {"$text": "I Like You So Much Better When You're Naked"}, "subtitle": {}, "artist": {"$text": "Ida Maria"}, "composer": {}, "discNum": {"$text": "1"}, "trackNum": {"$text": "1"}, "licensing": {}, "publisher": {}, "album": {"albumId": {"$text": "98387158"}, "albumTitle": {"$text": "Fortress Round Your Heart"}, "albumArtist": {"$text": "Ida Maria"}, "albumYear": {"$text": "2008"}, "upc": {}, "label": {}, "labelNum": {}, "promoUrl": {}, "musicType": {"$text": "not specified"}, "coverUrl": {"$text": "N/A"}}}], "text": [{"paragraph": {"num": "1", "$text": "The New York-based band Beirut travels to Mexico for its latest album: a brassy, adventurous double EP called March of Zapotec.  It won't be released until the end of February, but you can hear a sneak preview here with the song, \"The Shrew.\"  Also on this edition of All Songs Considered:  an ambitious debut release from the seven-piece, Nashville-based ensemble Darla Farmer; a collaboration between David Byrne and the Dirty Projectors, as part of a new album to promote AIDS awareness; a moody, gorgeous new album from Mali's Rokia Traore; new music from the seemingly tortured Antony and the Johnsons; a solo release from AC Newman of the New Pornographers; and Norwegian punk-pop singer Ida Maria."}, "paragraph": {"num": "2", "$text": "Download this show in the All Songs Considered podcast."}, "paragraph": {"num": "3", "$text": "Sign up for the All Songs Considered newsletter and we'll tell you when new music features are available on the site."}, "paragraph": {"num": "4", "$text": "Register with the NPR.org community to join in our discussions."}, "paragraph": {"num": "5", "$text": "Contact us with your questions and comments.  Copyright 2009 National Public Radio"}}], "textWithHtml": [{"paragraph": {"num": "1", "$text": "The New York-based band <a href=\"http://www.npr.org/templates/story/story.php?storyId=15148770\">Beirut</a> travels to Mexico for its latest album: a brassy, adventurous double EP called <em>March of Zapotec</em>.  It won't be released until the end of February, but you can hear a sneak preview here with the song, \"The Shrew.\"  Also on this edition of <em>All Songs Considered</em>:  an ambitious debut release from the seven-piece, Nashville-based ensemble Darla Farmer; a collaboration between <a href=\"http://www.npr.org/templates/story/story.php?storyId=15320822\">David Byrne</a> and the <a href=\"http://www.npr.org/templates/story/story.php?storyId=15735067\">Dirty Projectors</a>, as part of a new album to promote AIDS awareness; a moody, gorgeous new album from Mali's <a href=\"http://www.npr.org/templates/story/story.php?storyId=14995698\">Rokia Traore</a>; new music from the seemingly tortured <a href=\"http://www.npr.org/templates/story/story.php?storyId=15239231\">Antony and the Johnsons</a>; a solo release from <a href=\"http://www.npr.org/templates/story/story.php?storyId=16149139\">AC Newman</a> of the <a href=\"http://www.npr.org/templates/story/story.php?storyId=99347326\">New Pornographers</a>; and Norwegian punk-pop singer Ida Maria."}, "paragraph": {"num": "2", "$text": "<a href=\"http://www.npr.org/rss/podcast/podcast_detail.php?siteId=4819413&ps=mpm\">Download this show</a> in the <em>All Songs Considered</em> <a href=\"http://www.npr.org/rss/podcast/podcast_detail.php?siteId=4819413&ps=mpm\">podcast</a>."}, "paragraph": {"num": "3", "$text": "<a href=\"http://www.npr.org/templates/reg/\">Sign up</a> for the <em>All Songs Considered</em> <a href=\"http://www.npr.org/templates/reg/\">newsletter</a> and we'll tell you when new music features are available on the site."}, "paragraph": {"num": "4", "$text": "<a href=\"http://www.npr.org/templates/reg/\">Register with the NPR.org community</a> to join in our discussions."}, "paragraph": {"num": "5", "$text": "<a href=\"mailto:allsongs@npr.org\">Contact us</a> with your questions and comments.  Copyright 2009 National Public Radio. To see more, visit <a href=\"http://www.npr.org/\">http://www.npr.org/</a>.<img src=\"http://media.npr.org/images/xanadu.gif?apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001\" />"}}]}, {"id": "90245765", "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=90245765&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=90245765&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}], "title": {"$text": "BPP Jukebox: Dust Off the Dirty Projectors"}, "partnerId": {}, "subtitle": {}, "shortTitle": {}, "teaser": {"$text": "We put a quarter in the BPP Jukebox, and out came this single from the Dirty Projectors, the band that reworked Black Flag's punk classic, <em>Damaged</em>."}, "miniTeaser": {"$text": "A second listen to the Dirty Projectors' reworking of a Black Flag punk classic."}, "slug": {"$text": "Studio Sessions"}, "thumbnail": {}, "storyDate": {"$text": "Wed, 07 May 2008 07:00:00 -0400"}, "pubDate": {"$text": "Wed, 07 May 2008 09:48:00 -0400"}, "lastModifiedDate": {"$text": "Wed, 07 May 2008 14:37:44 -0400"}, "show": [{"program": {"id": "47", "code": "BPP", "$text": "The Bryant Park Project"}, "showDate": {"$text": "Wed, 07 May 2008 07:00:00 -0400"}, "segNum": {"$text": "16"}}], "keywords": {}, "priorityKeywords": {}, "organization": [{"orgId": "1", "orgAbbr": "NPR", "name": {"$text": "National Public Radio"}, "website": {"$text": "http://www.npr.org/"}}], "transcript": {"link": {"type": "api", "$text": "http://api.npr.org/transcript?id=90245765&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}}, "parent": [{"id": "91882122", "type": "newsPackage", "title": {"$text": "Bryant Park Project Video"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=91882122&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=91882122&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "10001", "type": "genre", "title": {"$text": "Rock/Pop/Folk"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=10001&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=10001&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "1103", "type": "primaryTopic", "slug": "true", "title": {"$text": "Studio Sessions"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=1103&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=1103&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "1103", "type": "topic", "slug": "true", "title": {"$text": "Studio Sessions"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=1103&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=1103&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}], "childStory": [{"id": "17122446", "num": "1", "link": {"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=17122446&ft=3&f=15735067"}, "link": {"type": "api", "$text": "http://api.npr.org/query?id=17122446&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}}], "audio": [{"id": "90245715", "type": "primary", "title": {}, "duration": {"$text": "0"}, "format": {"mp3": {"type": "m3u", "$text": "http://api.npr.org/m3u/190245715-93b697.m3u?orgId=1&topicId=1103&aggIds=91882122&ft=3&f=15735067"}, "wm": {"$text": "http://www.npr.org/templates/dmg/dmg_wmref_em.php?id=90245715&type=1&mtype=WM&orgId=1&topicId=1103&aggIds=91882122&ft=3&f=15735067"}, "rm": {"$text": "http://www.npr.org/templates/dmg/dmg_rpm.rpm?id=90245715&type=1&mtype=RM&orgId=1&topicId=1103&aggIds=91882122&ft=3&f=15735067"}}, "rightsHolder": {}, "permissions": {"download": {"allow": "true"}, "stream": {"allow": "true"}, "embed": {"allow": "true"}}}], "container": [{"id": "90248752", "title": {"$text": "Related NPR Stories"}, "introText": {}, "colSpan": {"$text": "1"}, "displayOptions": {"typeId": "2", "$text": "Display Both"}, "link": {"refId": "90248755", "num": "1"}}], "relatedLink": [{"id": "90248755", "type": "internal", "caption": {"$text": "Remaking a Punk Classic from Memory"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=13969414&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=13969414&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}], "artist": [{"id": "90248536", "artistId": {"$text": "15735067"}, "name": {"$text": "The Dirty Projectors"}}]}, {"id": "17122446", "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=17122446&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=17122446&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}], "title": {"$text": "Dirty Projectors Let Black Flag Fly"}, "partnerId": {}, "subtitle": {}, "shortTitle": {}, "teaser": {"$text": "The Dirty Projectors, a Brooklyn band, remakes a classic record from the punk band Black Flag &mdash; from memory. The group stops in for a taste of <em>Rise Above</em>."}, "miniTeaser": {"$text": "The Dirty Projectors remakes a classic record from the punk band Black Flag &mdash; from memory."}, "slug": {"$text": "Video Sessions"}, "storyDate": {"$text": "Tue, 11 Dec 2007 07:00:00 -0500"}, "pubDate": {"$text": "Tue, 11 Dec 2007 07:58:00 -0500"}, "lastModifiedDate": {"$text": "Wed, 07 May 2008 09:55:26 -0400"}, "show": [{"program": {"id": "47", "code": "BPP", "$text": "The Bryant Park Project"}, "showDate": {"$text": "Tue, 11 Dec 2007 07:00:00 -0500"}, "segNum": {"$text": "9"}}], "keywords": {}, "priorityKeywords": {}, "organization": [{"orgId": "1", "orgAbbr": "NPR", "name": {"$text": "National Public Radio"}, "website": {"$text": "http://www.npr.org/"}}], "transcript": {"link": {"type": "api", "$text": "http://api.npr.org/transcript?id=17122446&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}}, "parent": [{"id": "90245765", "type": "parent", "title": {"$text": "BPP Jukebox: Dust Off the Dirty Projectors"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=90245765&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=90245765&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "17759388", "type": "parent", "title": {"$text": "Cleaning Up with the Dirty Projectors"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=17759388&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=17759388&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "15668660", "type": "series", "slug": "true", "title": {"$text": "Video Sessions"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=15668660&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=15668660&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "10001", "type": "genre", "title": {"$text": "Rock/Pop/Folk"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=10001&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=10001&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "1110", "type": "topic", "title": {"$text": "Music Videos"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=1110&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=1110&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "1105", "type": "topic", "title": {"$text": "Music Interviews & Profiles"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=1105&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=1105&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "1103", "type": "topic", "title": {"$text": "Studio Sessions"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=1103&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=1103&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}], "audio": [{"id": "17122408", "type": "primary", "title": {}, "duration": {"$text": "0"}, "format": {"mp3": {"type": "m3u", "$text": "http://api.npr.org/m3u/117122408-ccf4c1.m3u?orgId=1&topicId=1039&aggIds=15668660&ft=3&f=15735067"}, "wm": {"$text": "http://www.npr.org/templates/dmg/dmg_wmref_em.php?id=17122408&type=1&mtype=WM&orgId=1&topicId=1039&aggIds=15668660&ft=3&f=15735067"}, "rm": {"$text": "http://www.npr.org/templates/dmg/dmg_rpm.rpm?id=17122408&type=1&mtype=RM&orgId=1&topicId=1039&aggIds=15668660&ft=3&f=15735067"}}, "rightsHolder": {}, "permissions": {"download": {"allow": "true"}, "stream": {"allow": "true"}, "embed": {"allow": "true"}}}], "artist": [{"id": "17139560", "artistId": {"$text": "15735067"}, "name": {"$text": "The Dirty Projectors"}}], "text": [{"paragraph": {"num": "1", "$text": "The Dirty Projectors' new CD, Rise Above, started when bandleader Dave Longstreth found an empty cassette case. It was for an old Black Flag album, Damaged. \"I was kind of like, 'Whoa, there's that album,'\" Longstreth says."}, "paragraph": {"num": "2", "$text": "Longstreth decided to remake the 1990 punk record &mdash; from memory. \"I just sort of began writing melodies, and then sort of distinct from the melodies I was making, thinking of the words as well as I could, and then just sort of pairing them as best I could,\" he says. "}, "paragraph": {"num": "3", "$text": "The result is more ethereal than thrash, intriguing and hard to catch, and yet true to the original."}, "paragraph": {"num": "4", "$text": "The Dirty Projectors' members stop in for a taste of Rise Above.  Copyright 2009 National Public Radio"}}], "textWithHtml": [{"paragraph": {"num": "1", "$text": "The Dirty Projectors' new CD, <em>Rise Above</em>, started when bandleader Dave Longstreth found an empty cassette case. It was for an old Black Flag album, <em>Damaged</em>. \"I was kind of like, 'Whoa, there's that album,'\" Longstreth says."}, "paragraph": {"num": "2", "$text": "Longstreth decided to remake the 1990 punk record &mdash; from memory. \"I just sort of began writing melodies, and then sort of distinct from the melodies I was making, thinking of the words as well as I could, and then just sort of pairing them as best I could,\" he says. "}, "paragraph": {"num": "3", "$text": "The result is more ethereal than thrash, intriguing and hard to catch, and yet true to the original."}, "paragraph": {"num": "4", "$text": "The Dirty Projectors' members stop in for a taste of <em>Rise Above</em>.  Copyright 2009 National Public Radio. To see more, visit <a href=\"http://www.npr.org/\">http://www.npr.org/</a>.<img src=\"http://media.npr.org/images/xanadu.gif?apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001\" />"}}]}, {"id": "15965475", "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=15965475&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=15965475&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}], "title": {"$text": "David Byrne, Beirut, Dirty Projectors"}, "partnerId": {}, "subtitle": {}, "shortTitle": {}, "teaser": {"$text": "A rare re-issue from David Byrne; Balkan Brass via the New York band Beirut; Wood spoons, laptop tunes: Tender Forever; More surprises from singer Nellie McKay; Black Flag memories from Dirty Projectors; The tainted love and fight songs of Shivaree"}, "miniTeaser": {"$text": "A rare re-issue from David Byrne; Balkan Brass via the New York band Beirut; Wood spoons, laptop..."}, "slug": {"$text": "All Songs Considered"}, "thumbnail": {"medium": {"$text": "http://media.npr.org/programs/asc/archives/20071018/images/shivaree75.jpg?t=1248630452"}}, "storyDate": {"$text": "Thu, 18 Oct 2007 12:00:00 -0400"}, "pubDate": {"$text": "Thu, 18 Oct 2007 12:00:00 -0400"}, "lastModifiedDate": {"$text": "Wed, 16 Jul 2008 16:20:34 -0400"}, "show": [{"program": {"id": "37", "code": "ASC", "$text": "All Songs Considered"}, "showDate": {"$text": "Thu, 18 Oct 2007 12:00:00 -0400"}, "segNum": {"$text": "1"}}], "keywords": {}, "priorityKeywords": {}, "organization": [{"orgId": "1", "orgAbbr": "NPR", "name": {"$text": "National Public Radio"}, "website": {"$text": "http://www.npr.org/"}}], "parent": [{"id": "10001", "type": "genre", "title": {"$text": "Rock/Pop/Folk"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=10001&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=10001&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "1108", "type": "primaryTopic", "title": {"$text": "Discover Songs"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=1108&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=1108&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "1108", "type": "topic", "title": {"$text": "Discover Songs"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=1108&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=1108&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}], "audio": [{"id": "15965478", "type": "primary", "title": {}, "duration": {"$text": "0"}, "format": {"mp3": {"type": "m3u", "$text": "http://api.npr.org/m3u/115965478-5a4e3d.m3u?orgId=1&topicId=1108&ft=3&f=15735067"}, "wm": {"$text": "http://www.npr.org/templates/dmg/dmg_wmref_em.php?id=15965478&type=1&mtype=WM&orgId=1&topicId=1108&ft=3&f=15735067"}, "rm": {"$text": "http://www.npr.org/templates/dmg/dmg_rpm.rpm?id=15965478&type=1&mtype=RM&orgId=1&topicId=1108&ft=3&f=15735067"}}, "rightsHolder": {}, "permissions": {"download": {"allow": "true"}, "stream": {"allow": "true"}, "embed": {"allow": "true"}}}], "product": [{"id": "17094154", "type": "CD", "title": {"$text": "The Flying Club Cup"}, "author": {"$text": "Beirut"}, "upc": {"$text": "600197005521"}, "publisher": {}, "publishYear": {"$text": "0"}, "purchaseLink": {}}, {"id": "17094160", "type": "CD", "title": {"$text": "Wider"}, "author": {"$text": "Tender Forever"}, "upc": {"$text": "789856118823"}, "publisher": {}, "publishYear": {"$text": "0"}, "purchaseLink": {}}, {"id": "17094170", "type": "CD", "title": {"$text": "Obligatory Villagers"}, "author": {"$text": "Nellie McKay"}, "upc": {"$text": "015707984324"}, "publisher": {}, "publishYear": {"$text": "0"}, "purchaseLink": {}}, {"id": "17094176", "type": "CD", "title": {"$text": "Rise Above"}, "author": {"$text": "Dirty Projectors"}, "upc": {"$text": "656605130125"}, "publisher": {}, "publishYear": {"$text": "0"}, "purchaseLink": {}}, {"id": "17094186", "type": "CD", "title": {"$text": "Tainted Love: Mating Calls and Fight Songs"}, "author": {"$text": "Shivaree"}, "upc": {"$text": "601143109225"}, "publisher": {}, "publishYear": {"$text": "0"}, "purchaseLink": {}}, {"id": "17094192", "type": "CD", "title": {"$text": "The Knee Plays"}, "author": {"$text": "David Byrne"}, "upc": {"$text": "075597996784"}, "publisher": {}, "publishYear": {"$text": "0"}, "purchaseLink": {}}], "image": [{"id": "17094152", "type": "standard", "width": "150", "src": "http://media.npr.org/programs/asc/archives/20071018/images/beirutcvr.jpg?t=1248630452", "hasBorder": "false", "title": {"$text": "The Flying Club Cup"}, "caption": {}, "link": {"url": ""}, "producer": {}, "provider": {"url": ""}, "copyright": {}}, {"id": "17094158", "type": "standard", "width": "150", "src": "http://media.npr.org/programs/asc/archives/20071018/images/forevercvr.jpg?t=1248630452", "hasBorder": "false", "title": {"$text": "Wider"}, "caption": {}, "link": {"url": ""}, "producer": {}, "provider": {"url": ""}, "copyright": {}}, {"id": "17094168", "type": "standard", "width": "150", "src": "http://media.npr.org/programs/asc/archives/20071018/images/mckaycvr.jpg?t=1248630452", "hasBorder": "false", "title": {"$text": "Obligatory Villagers"}, "caption": {}, "link": {"url": ""}, "producer": {}, "provider": {"url": ""}, "copyright": {}}, {"id": "17094174", "type": "standard", "width": "150", "src": "http://media.npr.org/programs/asc/archives/20071018/images/projectorscvr.jpg?t=1248630452", "hasBorder": "false", "title": {"$text": "Rise Above"}, "caption": {}, "link": {"url": ""}, "producer": {}, "provider": {"url": ""}, "copyright": {}}, {"id": "17094184", "type": "standard", "width": "150", "src": "http://media.npr.org/programs/asc/archives/20071018/images/shivareecvr.jpg?t=1248630452", "hasBorder": "false", "title": {"$text": "Tainted Love: Mating Calls and Fight Songs"}, "caption": {}, "link": {"url": ""}, "producer": {}, "provider": {"url": ""}, "copyright": {}}, {"id": "17094190", "type": "standard", "width": "150", "src": "http://media.npr.org/programs/asc/archives/20071018/images/byrnecvr.jpg?t=1248630452", "hasBorder": "false", "title": {"$text": "The Knee Plays"}, "caption": {}, "link": {"url": ""}, "producer": {}, "provider": {"url": ""}, "copyright": {}}, {"id": "15965476", "type": "standard", "width": "200", "src": "http://media.npr.org/programs/asc/archives/20071018/images/collage.jpg?t=1248630452&s=12", "hasBorder": "false", "title": {"$text": "All Songs Considered show image"}, "caption": {}, "link": {"url": ""}, "producer": {}, "provider": {"url": ""}, "copyright": {}}, {"id": "110910263", "type": "standard", "width": "75", "src": "http://media.npr.org/programs/asc/archives/20071018/images/shivaree75.jpg?t=1248630452", "hasBorder": "false", "title": {"$text": "thumbnail"}, "caption": {}, "link": {"url": ""}, "producer": {}, "provider": {"url": ""}, "copyright": {}}], "artist": [{"id": "16107841", "artistId": {"$text": "15320822"}, "name": {"$text": "David Byrne"}}, {"id": "16107844", "artistId": {"$text": "15148770"}, "name": {"$text": "Beirut"}}, {"id": "16107847", "artistId": {"$text": "16107815"}, "name": {"$text": "Tender Forever"}}, {"id": "16107850", "artistId": {"$text": "15318718"}, "name": {"$text": "Nellie McKay"}}, {"id": "16107853", "artistId": {"$text": "15735067"}, "name": {"$text": "The Dirty Projectors"}}, {"id": "16107856", "artistId": {"$text": "15731528"}, "name": {"$text": "Shivaree"}}], "song": [{"id": "16107831", "title": {"$text": "St. Apollonia"}, "subtitle": {}, "artist": {"$text": "Beirut"}, "composer": {"$text": "Condon"}, "discNum": {"$text": "1"}, "trackNum": {"$text": "12"}, "licensing": {}, "publisher": {"$text": "Condon"}, "album": {"albumId": {"$text": "15458734"}, "albumTitle": {"$text": "Flying Club Cup"}, "albumArtist": {"$text": "Beirut"}, "albumYear": {"$text": "2007"}, "upc": {"$text": "600197005514"}, "label": {"$text": "Ba Da Bing!"}, "labelNum": {"$text": "55"}, "promoUrl": {}, "musicType": {"$text": "rock"}, "coverUrl": {"$text": "/images/amg/pop/cov75/drj100/j100/j10029ljmb9.jpg"}}}, {"id": "17094163", "title": {"$text": "No One Will Tell No One For Sure"}, "subtitle": {}, "artist": {"$text": "Tender Forever"}, "composer": {}, "discNum": {"$text": "1"}, "trackNum": {"$text": "5"}, "licensing": {}, "publisher": {}, "album": {"albumId": {"$text": "17094162"}, "albumTitle": {"$text": "Wider"}, "albumArtist": {"$text": "Tender Forever"}, "albumYear": {"$text": "1969"}, "upc": {"$text": "789856118823"}, "label": {}, "labelNum": {}, "promoUrl": {}, "musicType": {"$text": "not specified"}, "coverUrl": {"$text": "http://media.npr.org/programs/asc/archives/20071018/images/forevercvr.jpg"}}}, {"id": "16107835", "title": {"$text": "Mother of Pearl"}, "subtitle": {}, "artist": {"$text": "Nellie McKay"}, "composer": {"$text": "McKay"}, "discNum": {"$text": "1"}, "trackNum": {"$text": "1"}, "licensing": {}, "publisher": {"$text": "McKay"}, "album": {"albumId": {"$text": "15891186"}, "albumTitle": {"$text": "Obligatory Villagers"}, "albumArtist": {"$text": "Nellie McKay"}, "albumYear": {"$text": "2007"}, "upc": {"$text": "015707984324"}, "label": {"$text": "Hungry Mouse"}, "labelNum": {"$text": "79843"}, "promoUrl": {}, "musicType": {"$text": "rock"}, "coverUrl": {"$text": "/images/amg/pop/cov75/drj000/j043/j04314fzdi2.jpg"}}}, {"id": "17094179", "title": {"$text": "Rise Above"}, "subtitle": {}, "artist": {"$text": "Dirty Projectors"}, "composer": {}, "discNum": {"$text": "1"}, "trackNum": {"$text": "10"}, "licensing": {}, "publisher": {}, "album": {"albumId": {"$text": "17094178"}, "albumTitle": {"$text": "Rise Above"}, "albumArtist": {"$text": "Dirty Projectors"}, "albumYear": {"$text": "1969"}, "upc": {"$text": "656605130125"}, "label": {}, "labelNum": {}, "promoUrl": {}, "musicType": {"$text": "not specified"}, "coverUrl": {"$text": "http://media.npr.org/programs/asc/archives/20071018/images/projectorscvr.jpg"}}}, {"id": "16107839", "title": {"$text": "Paradise"}, "subtitle": {}, "artist": {"$text": "Shivaree"}, "composer": {"$text": "Spector/Botkin/Garf"}, "discNum": {"$text": "1"}, "trackNum": {"$text": "1"}, "licensing": {}, "publisher": {"$text": "Spector/Botkin/Garf"}, "album": {"albumId": {"$text": "15731527"}, "albumTitle": {"$text": "Tainted Love: Mating Calls & Fight Songs"}, "albumArtist": {"$text": "Shivaree"}, "albumYear": {"$text": "2007"}, "upc": {"$text": "601143109225"}, "label": {"$text": "Zoe"}, "labelNum": {"$text": "01143"}, "promoUrl": {}, "musicType": {"$text": "rock"}, "coverUrl": {"$text": "/images/amg/pop/cov75/dri800/i850/i85061d4ziy.jpg"}}}, {"id": "17094195", "title": {"$text": "The Sound of Business"}, "subtitle": {}, "artist": {"$text": "David Byrne"}, "composer": {}, "discNum": {"$text": "1"}, "trackNum": {"$text": "3"}, "licensing": {}, "publisher": {}, "album": {"albumId": {"$text": "17094194"}, "albumTitle": {"$text": "The Knee Plays"}, "albumArtist": {"$text": "David Byrne"}, "albumYear": {"$text": "1969"}, "upc": {"$text": "075597996784"}, "label": {}, "labelNum": {}, "promoUrl": {}, "musicType": {"$text": "not specified"}, "coverUrl": {"$text": "http://media.npr.org/programs/asc/archives/20071018/images/byrnecvr.jpg"}}}, {"id": "16107829", "title": {"$text": "Sound of Business"}, "subtitle": {}, "artist": {"$text": "David Byrne"}, "composer": {"$text": "Byrne"}, "discNum": {"$text": "1"}, "trackNum": {"$text": "3"}, "licensing": {}, "publisher": {"$text": "Byrne"}, "album": {"albumId": {"$text": "15486034"}, "albumTitle": {"$text": "Music for \"The Knee Plays\""}, "albumArtist": {"$text": "David Byrne"}, "albumYear": {"$text": "1985"}, "upc": {}, "label": {"$text": "Regal Zonophone"}, "labelNum": {"$text": "2403811"}, "promoUrl": {}, "musicType": {"$text": "rock"}, "coverUrl": {"$text": "/images/amg/pop/cov75/drj100/j119/j11995npprl.jpg"}}}, {"id": "16107833", "title": {"$text": "No One Will Tell No One for Sure"}, "subtitle": {}, "artist": {"$text": "Tender Forever"}, "composer": {"$text": "Tender Forever/Vale"}, "discNum": {"$text": "1"}, "trackNum": {"$text": "5"}, "licensing": {}, "publisher": {"$text": "Tender Forever/Vale"}, "album": {"albumId": {"$text": "16107813"}, "albumTitle": {"$text": "Wider"}, "albumArtist": {"$text": "Tender Forever"}, "albumYear": {"$text": "2007"}, "upc": {"$text": "AMG000069081"}, "label": {"$text": "K"}, "labelNum": {"$text": "188"}, "promoUrl": {}, "musicType": {"$text": "rock"}, "coverUrl": {"$text": "/images/amg/pop/cov75/drj000/j054/j05429yhhz9.jpg"}}}, {"id": "16107837", "title": {"$text": "Rise Above"}, "subtitle": {}, "artist": {"$text": "The Dirty Projectors"}, "composer": {"$text": "Ginn"}, "discNum": {"$text": "1"}, "trackNum": {"$text": "10"}, "licensing": {}, "publisher": {"$text": "Ginn"}, "album": {"albumId": {"$text": "16107814"}, "albumTitle": {"$text": "Rise Above"}, "albumArtist": {"$text": "The Dirty Projectors"}, "albumYear": {"$text": "2007"}, "upc": {"$text": "088387004102"}, "label": {"$text": "Rough Trade"}, "labelNum": {"$text": "410"}, "promoUrl": {}, "musicType": {"$text": "rock"}, "coverUrl": {"$text": "/images/amg/pop/cov75/dri900/i963/i96313supb6.jpg"}}}], "text": [{"paragraph": {"num": "1", "$text": "A rare re-issue from David Byrne; Balkan Brass via the New York band Beirut; Wood spoons, laptop tunes: Tender Forever; More surprises from singer Nellie McKay; Black Flag memories from Dirty Projectors; The tainted love and fight songs of Shivaree"}, "paragraph": {"num": "2", "$text": "Download this show in the All Songs Considered podcast."}, "paragraph": {"num": "3", "$text": "Sign up for the All Songs Considered newsletter and we'll tell you when new music features are available on the site.  Copyright 2009 National Public Radio"}}], "textWithHtml": [{"paragraph": {"num": "1", "$text": "A rare re-issue from David Byrne; Balkan Brass via the New York band Beirut; Wood spoons, laptop tunes: Tender Forever; More surprises from singer Nellie McKay; Black Flag memories from Dirty Projectors; The tainted love and fight songs of Shivaree"}, "paragraph": {"num": "2", "$text": "<a href=\"http://www.npr.org/rss/podcast/podcast_detail.php?siteId=4819413&ps=mpm\">Download this show</a> in the <em>All Songs Considered</em> <a href=\"http://www.npr.org/rss/podcast/podcast_detail.php?siteId=4819413&ps=mpm\">podcast</a>."}, "paragraph": {"num": "3", "$text": "<a href=\"/email/\">Sign up</a> for the <em>All Songs Considered</em> <a href=\"/email/\">newsletter</a> and we'll tell you when new music features are available on the site.  Copyright 2009 National Public Radio. To see more, visit <a href=\"http://www.npr.org/\">http://www.npr.org/</a>.<img src=\"http://media.npr.org/images/xanadu.gif?apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001\" />"}}]}, {"id": "13969414", "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=13969414&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=13969414&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}], "title": {"$text": "Remaking a Punk Classic from Memory"}, "partnerId": {}, "subtitle": {}, "shortTitle": {}, "teaser": {"$text": "The Dirty Projectors' songs mate controlled cacophony and catchy melody. Those extremes dominate the band's new <em>Rise Above</em>, on which it attempts to reconstruct and remake Black Flag's 1981 album <em>Damaged</em>."}, "miniTeaser": {"$text": "On \"Rise Above,\" The Dirty Projectors' members take on a Black Flag song in unconventional ways."}, "slug": {"$text": "Song Of The Day"}, "thumbnail": {"medium": {"$text": "http://media.npr.org/music/sotd/2007/08/projectors75.jpg?t=1248636536"}}, "storyDate": {"$text": "Mon, 27 Aug 2007 10:09:00 -0400"}, "pubDate": {"$text": "Mon, 27 Aug 2007 10:09:00 -0400"}, "lastModifiedDate": {"$text": "Mon, 29 Oct 2007 14:56:22 -0400"}, "keywords": {"$text": "dirty projectors, the dirty projectors"}, "priorityKeywords": {}, "organization": [{"orgId": "1", "orgAbbr": "NPR", "name": {"$text": "National Public Radio"}, "website": {"$text": "http://www.npr.org/"}}], "parent": [{"id": "4703895", "type": "series", "slug": "true", "title": {"$text": "Song Of The Day"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=4703895&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=4703895&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "10001", "type": "genre", "title": {"$text": "Rock/Pop/Folk"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=10001&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=10001&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "1108", "type": "topic", "title": {"$text": "Discover Songs"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=1108&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=1108&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "1108", "type": "primaryTopic", "title": {"$text": "Discover Songs"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=1108&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=1108&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "1104", "type": "topic", "title": {"$text": "Music Reviews"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=1104&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=1104&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "1008", "type": "topic", "title": {"$text": "Arts & Life"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=1008&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=1008&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}], "byline": [{"id": "13969624", "name": {"personId": "7421192", "$text": "Michael Katzif"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=7421192&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=7421192&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}], "container": [{"id": "13969445", "title": {"$text": "Monday's Pick"}, "introText": {}, "colSpan": {"$text": "1"}, "displayOptions": {"typeId": "2", "$text": "Display Both"}, "listText": {"refId": "13969440", "num": "1"}}, {"id": "13969578", "title": {"$text": "Web Resources"}, "introText": {}, "colSpan": {"$text": "1"}, "displayOptions": {"typeId": "2", "$text": "Display Both"}, "link": {"refId": "13969588", "num": "1"}, "link": {"refId": "13969592", "num": "2"}}, {"id": "13969579", "title": {"$text": "Related NPR Stories"}, "introText": {}, "colSpan": {"$text": "1"}, "displayOptions": {"typeId": "2", "$text": "Display Both"}, "link": {"refId": "13969586", "num": "1"}, "link": {"refId": "13969590", "num": "2"}, "link": {"refId": "13969594", "num": "3"}, "link": {"refId": "13969596", "num": "4"}, "link": {"refId": "13969598", "num": "5"}}], "product": [{"id": "13969600", "type": "CD", "title": {"$text": "The Dirty Projectors"}, "author": {"$text": "Rise Above"}, "upc": {"$text": "656605130125"}, "publisher": {}, "publishYear": {"$text": "0"}, "purchaseLink": {}}], "image": [{"id": "110906934", "type": "standard", "width": "75", "src": "http://media.npr.org/music/sotd/2007/08/projectors75.jpg?t=1248636536", "hasBorder": "false", "title": {"$text": "thumbnail"}, "caption": {}, "link": {"url": ""}, "producer": {}, "provider": {"url": ""}, "copyright": {}}], "relatedLink": [{"id": "13969588", "type": "external", "caption": {"$text": "The Dirty Projectors' Site"}, "link": [{"type": "html", "$text": "http://www.westernvinyl.com/dirty_projectors.htm"}]}, {"id": "13969592", "type": "external", "caption": {"$text": "The Dirty Projectors' MySpace Page"}, "link": [{"type": "html", "$text": "http://www.myspace.com/dirtyprojectors"}]}, {"id": "13969586", "type": "internal", "caption": {"$text": "The Fall's Constant 'Reformation'"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=12037597&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=12037597&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "13969590", "type": "internal", "caption": {"$text": "A 'Redemption Song' for The Clash's Frontman"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=11927463&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=11927463&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "13969594", "type": "internal", "caption": {"$text": "Making Music History: Bad Brains at CBGB, 1982"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=6250173&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=6250173&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "13969596", "type": "internal", "caption": {"$text": "The Punk Revolution Will Be on DVD"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=5174735&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=5174735&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}, {"id": "13969598", "type": "internal", "caption": {"$text": "A Quieter Course for Punk Pioneer Ian MacKaye"}, "link": [{"type": "html", "$text": "http://www.npr.org/templates/story/story.php?storyId=4625784&ft=3&f=15735067"}, {"type": "api", "$text": "http://api.npr.org/query?id=4625784&apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001"}]}], "listText": [{"id": "13969440", "tag": "ul", "paragraph": {"num": "1", "$text": "Song: \"Rise Above\""}, "paragraph": {"num": "2", "$text": "Artist: The Dirty Projectors"}, "paragraph": {"num": "3", "$text": "CD: <em>Rise Above</em>"}, "paragraph": {"num": "4", "$text": "Genre: Rock"}}], "artist": [{"id": "15735095", "artistId": {"$text": "15735067"}, "name": {"$text": "The Dirty Projectors"}}], "text": [{"paragraph": {"num": "1", "$text": "Few would think to rework &mdash; or, in some sense, remake &mdash; a work as lauded and lambasted as Black Flag's 1981 album Damaged. When it was first released, Damaged was revolutionary, taking the furious energy of punk and heavy metal and approaching it with a harder edge. Black Flag's aggressive approach to social criticism and politically charged angst sparked widespread criticism of its lyrics, yet its experimental nature appealed to listeners and fellow musicians, who found the album groundbreaking and influential."}, "paragraph": {"num": "2", "$text": "It certainly influenced The Dirty Projectors, led by prolific and eclectic singer-songwriter Dave Longstreth, whose approach to arranging seems like a strange mating dance of controlled cacophony and catchy melody. Those extremes dominate the group's new Rise Above &mdash; a deconstruction and reassembly of Damaged. Refraining from straightforward covers, Longstreth reportedly re-created the album from, as he puts it, \"memory and intuition.\" The end result finds the songs all accounted for, yet with wildly reworked arrangements that force a double-take from even those most familiar with the original works. For fans of Damaged, it's hard not to marvel at the similarities while noticing the many differences."}, "paragraph": {"num": "3", "$text": "On the title track, as with much of the record, Longstreth neatly entangles crisp guitar playing, a chorus of female voices and a sturdy back beat, and takes the songs far away from punk and into less easily labeled territory. The song mixes the soaring vocal heroics of soul, the bite of '60s rock and subtle allusions to the dance grooves of Afrobeat, as Longstreth's voice channels Marvin Gaye and Bob Marley via Antony & The Johnsons.   "}, "paragraph": {"num": "4", "$text": "While both albums draw from difficult political eras, the music hardly feels hopeless or brooding, as The Dirty Projectors' reliance on pop helps couch the statements of Rise Above in optimism. Hearing this version, it's intriguing to hear the rage of Black Flag's original wash away and reveal more of a plea for change."}, "paragraph": {"num": "5", "$text": "Listen to yesterday's 'Song of the Day.'  Copyright 2009 National Public Radio"}}], "textWithHtml": [{"paragraph": {"num": "1", "$text": "Few would think to rework &mdash; or, in some sense, remake &mdash; a work as lauded and lambasted as Black Flag's 1981 album <em>Damaged</em>. When it was first released, <em>Damaged</em> was revolutionary, taking the furious energy of punk and heavy metal and approaching it with a harder edge. Black Flag's aggressive approach to social criticism and politically charged angst sparked widespread criticism of its lyrics, yet its experimental nature appealed to listeners and fellow musicians, who found the album groundbreaking and influential."}, "paragraph": {"num": "2", "$text": "It certainly influenced The Dirty Projectors, led by prolific and eclectic singer-songwriter Dave Longstreth, whose approach to arranging seems like a strange mating dance of controlled cacophony and catchy melody. Those extremes dominate the group's new <em>Rise Above</em> &mdash; a deconstruction and reassembly of <em>Damaged</em>. Refraining from straightforward covers, Longstreth reportedly re-created the album from, as he puts it, \"memory and intuition.\" The end result finds the songs all accounted for, yet with wildly reworked arrangements that force a double-take from even those most familiar with the original works. For fans of <em>Damaged</em>, it's hard not to marvel at the similarities while noticing the many differences."}, "paragraph": {"num": "3", "$text": "On the title track, as with much of the record, Longstreth neatly entangles crisp guitar playing, a chorus of female voices and a sturdy back beat, and takes the songs far away from punk and into less easily labeled territory. The song mixes the soaring vocal heroics of soul, the bite of '60s rock and subtle allusions to the dance grooves of Afrobeat, as Longstreth's voice channels Marvin Gaye and Bob Marley via Antony & The Johnsons.   "}, "paragraph": {"num": "4", "$text": "While both albums draw from difficult political eras, the music hardly feels hopeless or brooding, as The Dirty Projectors' reliance on pop helps couch the statements of <em>Rise Above</em> in optimism. Hearing this version, it's intriguing to hear the rage of Black Flag's original wash away and reveal more of a plea for change."}, "paragraph": {"num": "5", "$text": "<em>Listen to <a href=\"http://www.npr.org/templates/story/story.php?storyId=13923162\">yesterday's 'Song of the Day.'</a></em>  Copyright 2009 National Public Radio. To see more, visit <a href=\"http://www.npr.org/\">http://www.npr.org/</a>.<img src=\"http://media.npr.org/images/xanadu.gif?apiKey=MDA0Mzc5NzE2MDEyNTg4MzIzMjNkZjNhZQ001\" />"}}]}]}}
=end