; WhatPulse Information Script for mIRC 6.X
; Written by Scott Wilcox <sc0tt@sc0tt.ca>
; Thanks goto Splodgey, wasted.
;
; http://sc0tt.ca http://unlagged.org
;
; The is basic error checking included, although 
; more could be added. There are many possibilies
; for this script, i just don't have to time to
; go through them at the moment, but anyome with
; a little scripting knowledge could change this
; to fit their needs.
;
; PLEASE NOTE:
; 
; For this script to work, you need to enable your
; stats to be generated on the whatpulse server. To
; do this, login to the WhatPulse site, goto your 
; option and check "Generate XML statistics (webapi)"
; you will then need to wait until 3:00, 9:00, 15:00 
; or 21:00 GMT has passed to update your statistics.

on *:start: {
  %old = %wp_userid
  unset %wp_
  %wp_userid = %old
  wp_update
}

alias wp_update {
  if (%wp_userid !isnum) {
    set %wp_userid $$?="Enter Your WhatPulse User ID:"
    echo $colour(info text) -a *** WhatPulse User ID Set, please re-run /wp_update
    return
  }
  ; Check to see if socket is already in use.
  if ($sock(wp_socket)) {
    ; Return error message if so
    echo $colour(info text) -a *** WhatPulse is already updating stats, please wait.
    return
  }

  ; Socket not in use, echo out updating message
  echo $colour(info text) -a *** WhatPulse updating stats

  ; If the whatpulse server ever changes, this will 
  ; need to be updated too.
  sockopen wp_socket whatpulse.org 80
}

on *:sockopen:wp_socket: {
  if ($sockerr) {
    echo $colour(info text) *** error $sockerr when downloading
    return
  }
  unset %downloadlength %downloadready
  sockwrite -n $sockname GET /api/users/ $+ %wp_userid $+ .xml HTTP/1.0
  sockwrite -n $sockname Accept: */*
  sockwrite -n $sockname Host: whatpulse.org
  sockwrite -n $sockname User-Agent: http://sc0tt.ca v1.0
  sockwrite -n $sockname
}

on *:sockread:wp_socket:{
  if (%wp_downloadready != 1) {
    var %header
    sockread %header
    while ($sockbr) {
      if (Content-length: * iswm %header) {
        %wp_downloadlength = $gettok(%header,2,32)
      }
      elseif (* !iswm %header) {
        %wp_downloadready = 1
        %wp_downloadoffset = $sock($sockname).rcvd
        break
      }
      sockread %header
    }
  }
  sockread %c
  while ($sockbr) {
    set $+(% $+ wp_,$gettok($gettok(%c,2,60),1,62)) $gettok($gettok(%c,2,62),1,60)
    sockread 4096 %c
  }
  set %wp_lastupdated $ctime
}

on *:sockclose:wp_socket:{
  ; Socket has been closed, the stats were updated.
  echo $colour(info text) -a *** WhatPulse stats finished updating ( $+ %wp_downloadlength bytes downloaded).
}

alias wp_show {
  ; %wp_GeneratedTime 2005-03-28 21:00:20
  ; %wp_UserID 4152
  ; %wp_AccountName sc0tt
  ; %wp_Country United Kingdom
  ; %wp_DateJoined 2004-01-11
  ; %wp_Homepage http://sc0tt.ca
  ; %wp_LastPulse 2005-03-25 00:50:09
  ; %wp_Pulses 105
  ; %wp_TotalKeyCount 172224
  ; %wp_TotalMouseClicks 28750
  ; %wp_AvKeysPerPulse 1640
  ; %wp_AvClicksPerPulse 274
  ; %wp_AvKPS 0
  ; %wp_AvCPS 0
  ; %wp_Rank 30593
  ; %wp_TeamID 2818
  ; %wp_TeamName Mac
  ; %wp_TeamMembers 6
  ; %wp_TeamKeys 6679753
  ; %wp_TeamClicks 826313
  ; %wp_TeamDescription The Mac Whatpulse Team
  ; %wp_TeamDateFormed 20 October 2004 at 17:25:57
  ; %wp_RankInTeam 5
  ; %wp_lastupdated 1112042573
  ;
  ; The list above shows the variables that are set when you
  ; update the script. They are set globally, and you can use
  ; them in any way that you want to.
  ; For this example, I just used a /say
  //say  $+ %wp_AccountName $+ : [tkc / tmc / rank: %wp_TotalKeyCount / %wp_TotalMouseClicks / %wp_Rank $+ $chr(93) [lp: %wp_LastPulse $+ $chr(93) [avkps: %wp_AvKPS $+ $chr(93) [dj: %wp_DateJoined $+ $chr(93) [Country: %wp_Country $+ $chr(93) [hp: %wp_Homepage $+ $chr(93) [team: %wp_TeamName $+ $chr(93) $+ 
}

; Simple menus.
menu channel,nicklist,nicklist {
  WhatPulse Stats
  .Update: wp_update
  .Show in # $+ : wp_show
}
