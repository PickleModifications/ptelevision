var player;
var playerData;
$(document).ready(function() {
    $.post("https://ptelevision/pageLoaded", JSON.stringify({}))
})

function GetURLID(link) {
    if (link == null) return;
    let url = link.toString();
    var regExp = /^.*(youtu\.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*/;
    var match = url.match(regExp);
    if (match && match[2].length == 11) {
        return {type: "youtube", id: match[2]};
    } 
    else if (url.split("twitch.tv/").length > 1) {
        
        return {type: "twitch", id: url.split("twitch.tv/")[1]};
    }
}

function ChannelDisplay(channel, channelFound) {
    if (channel) {
        var temp = 'CH<span style="font-size: 18pt !important;"> </span>'
        if (channel > 9) {
            temp += channel
        }
        else {
            temp += ("0" + channel)
        }
        $("#overlay span").show()
        $("#overlay span").html(temp)
    }
    else {
        $("#overlay span").show()
        $("#overlay span").html("")
    }
    if (channelFound) {
        $("#tv-container").hide()
    }
    else {
        $("#tv-container").show()
    }
}

function SetVideo(video_data) {
    var url = video_data.url;
    var channel = video_data.channel;
    var data = GetURLID(url)
    
    playerData = data
    if (player) {
        player.destroy()
        player = null;
    }
    if (data) {
        if (data.type == "youtube") {
            player = new YT.Player('twitch-embed', {
                height: '100%',
                width: '100%',
                videoId: data.id,
                playerVars: {
                    'playsinline': 1,
                },
                events: {
                    'onReady': function(event) {
                        event.target.playVideo();
                        event.target.seekTo(video_data.time)
                    },
                    'onStateChange': function(event) {
                        if (event.data == YT.PlayerState.PLAYING) {
                            event.target.unMute();
                        }
                        else if (event.data == YT.PlayerState.PAUSED) {
                            
                        }
                    }
                }
            });
        }
        else if (data.type == "twitch") {
            player = new Twitch.Player("twitch-embed", {
                width: "100%",
                height: "100%",
                channel: data.id,
                volume: 1.0
            });
            player.addEventListener(Twitch.Embed.VIDEO_READY, function() {
                player.setMuted(false);
            });
        } 
        
        $("#overlay span").hide()
        $("#tv-container").hide()
    }
    if (channel) {
        ChannelDisplay(channel, url)
    }
}

function SetVolume(volume) {
    
    if (player && playerData && player.setVolume) {
        if (playerData.type == "twitch") {
            player.setMuted(false);
            player.setVolume(volume / 100.0);
        }
        else if (playerData.type == "youtube") {
            player.unMute();
            player.setVolume(volume);
        }
    }
}

function ShowNotification(channel, data) {
    $("#tv-container").addClass("notify")
    $("#tv-container div").addClass("notify")
    var display = $('#tv-container').is(':visible')
    $('#tv-container').show()
    $("#tv-container div").html("Channel #" + channel + (data ? (" ("+data.name+")") : "") + " is now " + (data ? "live!" : "offline."))

    setTimeout(function() {
        $("#tv-container").removeClass("notify")
        $("#tv-container div").removeClass("notify")
        $("#tv-container div").html("NO SIGNAL")
        if (!display) {
            $('#tv-container').hide()
        }
    }, 3500)
}

window.addEventListener("message", function(ev) {
    if (ev.data.setVideo) {
        SetVideo(ev.data.data)
    }
    else if (ev.data.setVolume) {
        SetVolume(ev.data.data)
    }
    else if (ev.data.showNotification) {
        ShowNotification(ev.data.channel, ev.data.data)
    }
})
$(document).ready(function() {
    ChannelDisplay()
})
