/*Name : TweeCool
 *version: 1.7 
 *Description: Get the latest tweets from twitter.
 *Website: www.tweecool.com
 *Licence: No licence, feel free to do whatever you want.
 *Author: TweeCool
 */
(function($) {
    $.fn.extend({

        tweecool : function(options) {

            var defaults = {
                username : 'tweecool',
                limit : 5,
                profile_image : true,
                show_time : true,
                show_media : false,
                                show_media_size: 'thumb',  //values: small, large, thumb, medium 
                                show_actions: false,
                                action_reply_icon: '&crarr;',
                                action_retweet_icon: '&prop;',
                                action_favorite_icon: '&#9733;',
                                profile_img_url: 'profile', //Values: profile, tweet 
                                show_retweeted_text: false //This will show the original tweet in order to avoid any truncated text, and also the "RT @tweecool:" is removed which helps with 140 character limit
                                
            }

            var options = $.extend(defaults, options);

            function xTimeAgo(time) {
                var nd = new Date();
                //var gmtDate = Date.UTC(nd.getFullYear(), nd.getMonth(), nd.getDate(), nd.getHours(), nd.getMinutes(), nd.getMilliseconds());
                var gmtDate = Date.parse(nd);
                var tweetedTime = time * 1000; //convert seconds to milliseconds
                var timeDiff = (gmtDate - tweetedTime) / 1000; //convert milliseconds to seconds
                
                var second = 1, minute = 60, hour = 60 * 60, day = 60 * 60 * 24, week = 60 * 60 * 24 * 7, month = 60 * 60 * 24 * 30, year = 60 * 60 * 24 * 365;

                if (timeDiff > second && timeDiff < minute) {
                    return Math.round(timeDiff / second) + " seconds ago";
                } else if (timeDiff >= minute && timeDiff < hour) {
                    return Math.round(timeDiff / minute) + " minutes ago";
                } else if (timeDiff >= hour && timeDiff < day) {
                    return Math.round(timeDiff / hour) + " hours ago";
                } else if (timeDiff >= day && timeDiff < week) {
                    return Math.round(timeDiff / day) + " days ago";
                } else if (timeDiff >= week && timeDiff < month) {
                    return Math.round(timeDiff / week) + " weeks ago";
                } else if (timeDiff >= month && timeDiff < year) {
                    return Math.round(timeDiff / month) + " months ago";
                } else {
                    return 'over a year ago';
                }

            }

            return this.each(function() {
                var o = options;
                var wrapper = $(this);
                var wInner = $('<span>').appendTo(wrapper);
                var urlpattern = /(\b(https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/ig;
                var usernamepattern = /@+(\w+)/ig;
                var hashpattern = /#+(\w+)/ig;
                                var pIMG, media, timestamp, abox, mtext;

                $.getJSON("https://www.api.tweecool.com/?screenname=" + o.username + "&count=" + o.limit, function(data) {

                    if (data.errors || data == null) {
                        wrapper.html('No tweets available.');
                        return false;
                    }

                    $.each(data.tweets, function(i, field) {
                                            
                                                if (o.profile_image) {
                                                    if( o.profile_img_url == 'tweet' ){
                                                        pIMG = '<a class="pull-left" href="https://twitter.com/' + o.username + '/status/'+field.id_str+'" target="_blank"><img class="media-object" style="width: 64px; height: 64px;" src="' + data.user.profile_image_url + '" alt="' + o.username + '" /></a>';
                                                    }else{
                                                        pIMG = '<a class="pull-left" href="https://twitter.com/' + o.username + '" target="_blank"><img class="media-object" style="width: 64px; height: 64px;" src="' + data.user.profile_image_url + '" alt="' + o.username + '" /></a>';
                                                    }
                                                }else{
                                                    pIMG = ''; 
                                                }

                        if (o.show_time) {
                            timestamp = xTimeAgo(field.timestamp);
                        }else{
                                                    timestamp = ''; 
                                                }
                                                
                                                if(o.show_media && field.media_url){
                                                   media = '<a href="https://twitter.com/' + o.username + '/status/'+field.id_str+'" target="_blank"><img src="' + field.media_url + ':'+o.show_media_size+'" alt="' + o.username + '" class="media" /></a>';
                                                }else{
                                                   media = ''; 
                                                }
                                                
                                                if( o.show_actions ){
                                                  abox = '<div class="action-box"><table>';
                                                  abox += '<tr class="ab_reply"><td><a title="Reply" href="https://twitter.com/intent/tweet?in_reply_to='+field.id_str+'">'+o.action_reply_icon+'</a></td></tr>';
                                                  abox += '<tr class="ab_retweet"><td><a title="Retweet" href="https://twitter.com/intent/retweet?tweet_id='+field.id_str+'">'+o.action_retweet_icon+'</a>'+( field.retweet_count_f != '' ?'<span>'+field.retweet_count_f+'</span>':'' )+'</td></tr>';
                                                  abox += '<tr class="ab_favorite"><td><a title="Favorite" href="https://twitter.com/intent/favorite?tweet_id='+field.id_str+'">'+o.action_favorite_icon+'</a>'+( field.favorite_count_f != '' ?'<span>'+field.favorite_count_f+'</span>':'' )+'</td></tr>';
                                                  abox += '</table></div>';
                                                }else{
                                                  abox = '';  
                                                }
                                                
                                                if( o.show_retweeted_text && field.retweeted_text ){
                                                   mtext = field.retweeted_text;  
                                                }else{
                                                   mtext =  field.text;
                                                }
                                                
                        //if(mtext.match(usernamepattern) != null){
                            var d = new Date(field.timestamp * 1000);
                            // alert(d.getUTCMonth());
                            console.log(field);
                        wInner.append('<div class="newest-classifieds"><div class="media">'+pIMG+'<div class="media-body"><p><a href="#"><strong>Gift Card Spread</strong></a></p><p>'+mtext+'</p></div></div><p class="text-right show-more"><a href="https://twitter.com/GiftCardSpread">More &rarr;</a></p></div>')    
                        
                    //}
                    });

                }).fail(function(jqxhr, textStatus, error) {
                    //var err = textStatus + ', ' + error;
                    wrapper.html('No tweets available');
                });

            });

        }
    });

})(jQuery); 
