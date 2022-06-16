#!/bin/bash


##### USER CHANGABLE SETTINGS ############################################################
tmdbKey="YOUR-TMDB-API-KEY"						# Your themoviedb.org API Key
OrginalSource="DVD"										# What was the original source, AKA DVD? Blueray? (for comments)
diskExtracter='MakeMKV v1.61.7'							# If extracted from disk, what tool did that? (for comments)
fileEncoder='Handbrake v1.5.1'							# What tool encoded/created the final media file? (for atom and comments)
whoEncode="im_L0r3"										# Who did the encoding work? (for comments)
mediaDir='/Volumes/media/_atomic/'													# Path to originals dir (must have trailing slash)
itunesDir='/Volumes/media/iTunes/iTunes Media/Automatically Add to TV.localized/'	# Path to destination dir (must have trailing slash)


##### DONT TOUCH BELOW HERE ##############################################################

ver="5.8.2"
clear; echo ""
echo " ############################################### "
echo " ###                                         ### "
echo " ###        atomicParsley helper v"$ver"      ### "
echo " ###           --> TV Edition <--            ### "
echo " ###                @im_L0r3                 ### "
echo " ###                L0r3.dev                 ### "
echo " ###                                         ### "
echo " ############################################### "


##### CHECK SCRIPT LAUNCH FLAGS ##########################################################
echo ""; echo "##### CHECK SCRIPT LAUNCH FLAGS #####"

full_run='false';		fullr='0'
lite_run='false';		liter='0'
dry_run='false';		dryr='0'
repor_run='false';		repor='0'

while getopts 'fldr' flag; do
	case "${flag}" in
		f) full_run=true ;;
		l) lite_run=true ;;
		d) dry_run=true ;;
		r) repor_run=true ;;
	esac
done

if "$full_run"; 		then echo "Full run (-f) option set"; 		fullr='1';	fi
if "$lite_run"; 		then echo "Lite run (-m) option set"; 		liter='1';	fi
if "$dry_run";			then echo "Dry run (-d) option set"; 		dryr='1';	fi
if "$repor_run";		then echo "Reprocess run (-r) option set"; 	repor='1';	fi

flag_check='0'
let flag_check=fullr+liter+dryr; echo ""; echo "Total flags set: $flag_check"

if [ "$flag_check" == '0' ]; then
	echo ""
	echo "No launch flags found..."
	echo "     All runs must include at least one flag"
	echo ""
	echo "FLAG OPTIONS ARE:"
	echo "    -f: FULL run"
	echo "    -l: LITE run"
	echo "    -d: DRY run"
	echo "    -r: REPROCESS run"
	echo ""
	echo "Exiting..."; echo ""
	exit
fi


##### -f and -l CANT BE USED TOGETHER #####
flag_conflict='0'
let flag_conflict=fullr+liter
if [ "$flag_conflict" -gt '1' ]; then echo ""; echo "Cant use -f and -l at the same time"; echo ""; exit; fi


###### -r RUNS MUST BE USED WITH -f #####
if [ "$repor_run" == '1' ]; then
	if [ "$full_run" == '0' ]; then
		echo ""; echo "-r cant be used without -f"; echo ""
	fi
fi



##### PRESET SOME STUFF N JUNK #####
newline=$'\n'
tmdbShowId='Unknown'
artFile='/tmp/poster.jpg'


##### CHECK FOR DEPENDENCIES AND BUILD PATHS #############################################
echo ""; echo "##### CHECK FOR DEPENDENCIES #####"


echo ""; echo "Checking for homebrew..."
brewPath=`which brew`
if [ -z "$brewPath" ]; then
	echo "homebrew NOT found/installed"
	echo 'Install it with # /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
	echo ""; exit
else
	echo "homebrew found at $brewPath"
fi


echo ""; echo "Checking for wget..."
wgetPath=`which wget`
if [ -z "$wgetPath" ]; then
	echo "wget NOT found/installed"
	echo "Install it: $ brew install wget"
	echo ""; exit
else
	echo "wget found at: $wgetPath"
fi


echo ""; echo "Checking for jq..."
jqPath=`which jq`
if [ -z "$jqPath" ]; then
	echo "jq NOT found/installed"
	echo "Install it: $ brew install jq"
	echo ""; exit
else
	echo "jq found at: $jqPath"
fi


echo ""; echo "Checking for ffmpeg..."
ffmpegPath=`which ffmpeg`
if [ -z "$ffmpegPath" ]; then
	echo "ffmpeg NOT found/installed"
	echo "Install it: $ brew install ffmpeg"
	echo ""; exit
else
	echo "ffmpeg found at: $ffmpegPath"
fi


echo ""; echo "Checking for AtomicParsley..."
AtomicParsleyPath=`which AtomicParsley`;
if [ -z "$AtomicParsleyPath" ]; then
	echo "AtomicParsley NOT found"
	echo "Install it: $ brew install AtomicParsley"
	echo ""; exit
else
	echo "AtomicParsley found at: $AtomicParsleyPath"
fi

echo ""; echo "Done checking for dependencies..."


##### DELETE ANY EXISTING ART FILE (all flags) #####
echo ""; echo "##### DELETE ANY EXISTING ART FILE #####"
rm "$artFile"
echo "Done deleting any existing art file..."


#### BEGIN PRIMARY LOOP (all flags) ######################################################

cd "$mediaDir"
ls -1 | grep -i ".m4v" | while read fileMedia; do
	
	echo ""; echo "############### STARTING NEW FILE ###############"
	echo "#################################################"
	echo "$fileMedia"


	##### CREATE PATHS (all flags) #######################################################
	echo ""; echo "##### CREATE PATHS (all flags) #####"
	curMedia="$mediaDir$fileMedia"; echo "Full file path: $curMedia"
	titleMedia=`echo "$fileMedia" | sed 's/.m4v//'`; echo "File title: $titleMedia";
	itunesAutoAddDest="${itunesDir}$fileMedia"; echo "File destination: $itunesAutoAddDest";


	##### FFMPEG: EXTRACT MEDIA INFO (all flags) #########################################
	echo ""; echo "##### FFMPEG: EXTRACT MEDIA INFO (all flags) #####"
	mediaAllInfo=`$ffmpegPath -i "$curMedia" 2>&1`
	# echo ""; echo "$mediaAllInfo"; echo ""
	echo "Done extracting media info with ffmpeg..."


	##### EXTRACT MEDIA DURATION (all flags) #############################################
	echo ""; echo "##### EXTRACT MEDIA DURATION (all flags) #####"
	movieFfHrsMinsSecs=`echo "$mediaAllInfo" | grep -m 2 'Duration' | tail -1 | sed 's/Duration://' | sed 's/.start.*[^.start.]*//' | sed 's/\,//g' | sed 's/ //g' | rev | cut -c 4- | rev`
	echo "$movieFfHrsMinsSecs"


	##### DETERMINE STREAM 0:0(video) CODEC (all flags) ##################################
	echo ""; echo "##### DETERMINE STREAM 0:0(video) CODEC (all flags) #####"
	movieVidCodec=`echo "$mediaAllInfo" | grep 'Stream #0:0' | tail -1 | sed 's/^.*.Video.//' | sed 's/ //g' | cut -c 1-4`; echo "Media codec: $movieVidCodec"


	##### DETERMINE STREAM 0:0(video) BIT RATE (all flags) ###############################
	echo ""; echo "##### DETERMINE STREAM 0:0(video) BIT RATE (all flags) #####"
	#movieVidRate=`echo "$mediaAllInfo" | grep 'Stream #0:0' | sed 's/kb.*$/kb/' | sed 's/^.*.,.//' | sed s'/ //'`
	movieVidRate=`echo "$mediaAllInfo" | grep 'Stream #0:0' | tail -1 | sed 's/kb.*$/kb/' | sed 's/^.*.,.//' | sed s'/ //'`; echo "Media bit rate: $movieVidRate"


	##### DETERMINE STREAM 0:0(video) RESOLUTION (all flags) #############################
	echo ""; echo "##### DETERMINE STREAM 0:0(video) RESOLUTION (all flags) #####"
	movieRes=`echo "$mediaAllInfo" | grep 'Stream #0:0' | tail -1 | sed 's/^.*yuv/yuv/' | sed 's/.(.*[^.(.]*//' | sed 's/yuv//'`; echo "Media resolution: $movieRes"


	##### SET HD STATE STRING (all flags) ################################################
	echo ""; echo "##### SET HD STATE STRING (all flags) #####"
	hdState='0'
	if [ "$movieRes" -ge '719' ]; then hdState="1"; fi
	if [ "$movieRes" -ge '1079' ]; then hdState="2"; fi
	echo "HD State: $hdState"


	##### TEST IF STREAM 0:1 IS ART (all flags) ##########################################
	streamOneTest=`echo "$mediaAllInfo" | grep 'Stream #0:1' | tail -1`
	if [[ "$streamOneTest" != *"mjpeg"* ]]; then
		##### DETERMINE STREAM 0:1(audio) CODEC, BIT RATE (all flags) ####################
		echo ""; echo "##### DETERMINE STREAM 0:1(audio) CODEC, BIT RATE (all flags) #####"
		movieAudCodecA=`echo "$mediaAllInfo" | grep 'Stream #0:1' | sed 's/^.*.Audio.//' | cut -c 2- | cut -c 1-3`
		movieAudRateA=`echo "$mediaAllInfo" | grep 'Stream #0:1' | sed 's/kb.*$/kb/' | sed 's/^.*.,.//' | sed s'/ //'`
		movieAudHzA=`echo "$mediaAllInfo" | grep 'Stream #0:1' | sed 's/Hz.*$/Hz/' | sed 's/^.*.,.//' | sed s'/ //'`
		echo "Aud 0:1 Codec: $movieAudCodecA"
		echo "Aud 0:1 Rate: $movieAudRateA/s"
		echo "Aud 0:1 Hz: $movieAudHzA"
		audOneAll="Aud 0:1 $movieAudCodecA $movieAudRateA/s"
	fi


	##### TEST IF STREAM 0:2 PRESENT (all flags) #########################################
	streamTwoTest=`echo "$mediaAllInfo" | grep 'Stream #0:2' | tail -1`
	if [ ! -z "$streamTwoTest" ]; then
		##### TEST IF STREAM 0:2 IS NOT ART #####
		if [[ "$streamTwoTest" != *"mjpeg"* ]]; then
			##### DETERMINE STREAM 0:2(audio) CODEC, BIT RATE (all flags) ###############
			echo ""; echo "##### DETERMINE STREAM 0:2(audio) CODEC, BIT RATE (all flags) ###############"
			movieAudCodecB=`echo "$mediaAllInfo" | grep 'Stream #0:2' | sed 's/^.*.Audio.//' | cut -c 2- | cut -c 1-3`
			movieAudRateB=`echo "$mediaAllInfo" | grep 'Stream #0:2' | sed 's/kb.*$/kb/' | sed 's/^.*.,.//' | sed s'/ //'`
			movieAudHzB=`echo "$mediaAllInfo" | grep 'Stream #0:2' | sed 's/Hz.*$/Hz/' | sed 's/^.*.,.//' | sed s'/ //'`	
			echo "Aud 0:2 Codec: $movieAudCodecB"
			echo "Aud 0:2 Rate: $movieAudRateB/s"
			echo "Aud 0:2 Hz: $movieAudHzB"
			audTwoAll="Aud 0:2 $movieAudCodecB $movieAudRateB/s"
		fi
	fi

	echo ""; echo "Done extracting media stream info..."


	##### EXTRACT SHOW SEASON (all flags) ################################################
	echo ""; echo "##### EXTRACT SHOW SEASON (all flags) #####"
	extractShowSeason=`echo "$titleMedia" | sed -e 's/.*s\(.*\)x.*/\1/' | cut -c1-2`
	echo "Extracted show season: $extractShowSeason"


	##### EXTRACT SHOW NAME (all flags) ##################################################
	echo ""; echo "##### EXTRACT SHOW NAME (all flags) #####"
	extractShowNameA=`echo "$titleMedia" | sed "s/.s$extractShowSeason.*[^.s$extractShowSeason.]*//"`
	extractShowNameB=`echo "$extractShowNameA" | sed 's/ /+/g'`
	echo "Extracted show name: $extractShowNameA"


	##### EXTRACT SHOW EPISODE (all flags) ###############################################
	echo ""; echo "##### EXTRACT SHOW EPISODE (all flags) #####"
	extractShowEpisode=`echo "$titleMedia" | sed "s/^.*.s$extractShowSeason.//" | cut -c 1-2`
	echo "Extracted show episode: $extractShowEpisode"


	##### EXTRACT EPISODE NAME (all flags) ###############################################
#	extractEpisodeName=`echo "$titleMedia" | sed "s/^.*.x$extractShowEpisode.//"`
#	echo "Extracted episode name: $extractEpisodeName"


	######################################################################################
	##### TMDB: GET TMDB API ID USING SHOW NAME (all flags) ##############################
	echo ""; echo "##### TMDB: GET TMDB API ID USING SHOW NAME (all flags) #####"
	tmdbSearchId=`curl -s -X GET \
	"https://api.themoviedb.org/3/search/tv?api_key=$tmdbKey&query=$extractShowNameB"`
	tmdbShowName=`echo "$tmdbSearchId" | jq ".results[0] .name" | sed 's/"//g'`
	tmdbShowId=`echo "$tmdbSearchId" | jq ".results[0] .id" | sed 's/"//g'`
	echo "TMDB Show Name: $tmdbShowName"
	echo "TMDB Show ID: $tmdbShowId"



##### MANUAL OVERRIDE #####
# If there are multiple shows with the same title on TMDB, put the exact show name and ID here
#tmdbShowName=''
#tmdbShowId=''


	##### ACCURACY CHECK: COMPAIR FILE SHOW NAME WITH TMDB API NAME (all flags) ##########
	echo ""; echo "##### ACCURACY CHECK: COMPAIR FILE SHOW NAME WITH TMDB API NAME (all flags) #####"
	if [[ $extractShowNameA != *"$tmdbShowName"* ]]; then
		echo "File show name: $extractShowNameA"
		echo "TMDB show name: $tmdbShowName"
		echo "Extracted show file name doesnt match TMDB show name, quitting..."
		echo ""
		exit
	elif [[ $extractShowNameA == *"$tmdbShowName"* ]]; then
		echo "File show name: $extractShowNameA"
		echo "TMDB show name: $tmdbShowName"
		echo "Extracted show file name matches TMDB show name, continuing..."
	fi


	##### TMDB API: GET MEDIA MPAA RATING (all flags) ####################################
	echo ""; echo "##### TMDB API: GET MEDIA MPAA RATING (all flags) #####"
	tmdbMediaRating=`curl -s -X GET \
	"https://api.themoviedb.org/3/tv/$tmdbShowId/content_ratings?api_key=$tmdbKey"`
	tmdbRatingCnt=`echo "$tmdbMediaRating" | jq '.results | length'`
	tmdbRatingLoop='0'
	while [ "$tmdbRatingLoop" -lt "$tmdbRatingCnt" ]
	do
		tmdbRating=`echo "$tmdbMediaRating" | jq ".results[$tmdbRatingLoop] | .iso_3166_1" | sed 's/"//g'`
		if [ "$tmdbRating" == "US" ]; then 
			tmdbRatingUS=`echo "$tmdbMediaRating" | jq ".results[$tmdbRatingLoop] | .rating" | sed 's/"//g'`; echo "TMDB US Rating: $tmdbRatingUS"
		fi
		let tmdbRatingLoop++
	done


	##### TBDB API: GET PRIMARY GENRE (all flags) ########################################
	echo ""; echo "##### TBDB API: GET PRIMARY GENRE (all flags) #####"
	tmdbGenre0=''
	tmdbSeriesGenre=`curl -s -X GET \
	"https://api.themoviedb.org/3/tv/$tmdbShowId?api_key=$tmdbKey"`		# echo "$tmdbSeriesGenre"
	tmdbGenre0=`echo "$tmdbSeriesGenre" | jq ".genres[0] | .name" | sed 's/"//g'`; echo "TMDB primary genre: $tmdbGenre0"
	echo "Done getting show genre..."



##########################################################################################
##### FULL RUNS (-f) #####################################################################
if [ "$fullr" -eq '1' ]; then


##### ADD DASHES TO tmdbShowName FOR TMDB EPISODE INFO API CALL (-f runs) ############
echo ""; echo "#### ADD DASHES TO tmdbShowName FOR TMDB EPISODE INFO API CALL (-f runs) #####"
tmdbShowNameDashes=`echo "$tmdbShowName" | sed 's/ /-/g'`
echo "API call show name: $tmdbShowNameDashes"

##### TMDB API: GET EPISODE SPECIFIC DATA (-f runs) ######################################
echo ""; echo "##### TMDB API: GET EPISODE SPECIFIC DATA (-f runs) #####"	
tmdbMediaData=`curl -s -X GET \
"https://api.themoviedb.org/3/tv/$tmdbShowId-$tmdbShowNameDashes/season/$extractShowSeason/episode/$extractShowEpisode?api_key=$tmdbKey"`	
#echo "$tmdbMediaData"
echo "Done getting media data from TMDB"

##### EXTRACT EPISODE DATA FROM TMDB API RESULTS (-f runs) ###############################
echo ""; echo "##### EXTRACT EPISODE DATA FROM TMDB API RESULTS (-f runs) #####"
tmdbAirDate=`echo "$tmdbMediaData" | jq ".air_date" | sed 's/"//g'`; echo "tmdbAirDate: $tmdbAirDate"
tmdbEpisode_number=`echo "$tmdbMediaData" | jq ".episode_number" | sed 's/"//g'`; echo "tmdbEpisode_number: $tmdbEpisode_number"
tmdbName=`echo "$tmdbMediaData" | jq ".name" | sed 's/"//g'`; echo "tmdbName: $tmdbName"
tmdbOverview=`echo "$tmdbMediaData" | jq ".overview" | sed 's/"//g'`; echo "tmdbOverview: $tmdbOverview"
tmdbId=`echo "$tmdbMediaData" | jq ".id" | sed 's/"//g'`; echo "tmdbId: $tmdbId"
tmdbProduction_code=`echo "$tmdbMediaData" | jq ".production_code" | sed 's/"//g'`; echo "tmdbProduction_code: $tmdbProduction_code"
tmdbSeason_number=`echo "$tmdbMediaData" | jq ".season_number" | sed 's/"//g'`; echo "tmdbSeason_number: $tmdbSeason_number"
tmdbStill_path=`echo "$tmdbMediaData" | jq ".still_path" | sed 's/"//g'`; echo "tmdbStill_path: $tmdbStill_path"
tmdbVote_average=`echo "$tmdbMediaData" | jq ".vote_average" | sed 's/"//g'`; echo "tmdbVote_average: $tmdbVote_average"
tmdbVote_count=`echo "$tmdbMediaData" | jq ".vote_count" | sed 's/"//g'`; echo "tmdbVote_count: $tmdbVote_count"
tmdbAirYear=`echo "$tmdbAirDate" | cut -c 1-4`; echo "tmdbAirYear: $tmdbAirYear"


##### TMDB API: GET MEDIA CAST/CREW/GUEST STARS (-f runs) ################################
echo ""; echo "##### TMDB API: GET MEDIA CAST/CREW/GUEST STARS (-f runs) #####"
tmdbCredits=`curl -s -X GET \
"https://api.themoviedb.org/3/tv/$tmdbShowId/season/$extractShowSeason/episode/$extractShowEpisode/credits?api_key=$tmdbKey"`
echo "Done getting cast/crew..."



##### EXTRACT CAST DATA FROM TMDB API RESULTS (-f runs) ##################################
echo ""; echo "##### EXTRACT CAST DATA FROM TMDB API RESULTS (-f runs) #####"

tmdbCast0=`echo "$tmdbCredits" | jq ".cast[0] | .name" | sed 's/"//g'`; echo "tmdbCast0: $tmdbCast0"
tmdbCast1=`echo "$tmdbCredits" | jq ".cast[1] | .name" | sed 's/"//g'`; echo "tmdbCast1: $tmdbCast1"
tmdbCast2=`echo "$tmdbCredits" | jq ".cast[2] | .name" | sed 's/"//g'`; echo "tmdbCast2: $tmdbCast2"
tmdbCast3=`echo "$tmdbCredits" | jq ".cast[3] | .name" | sed 's/"//g'`; echo "tmdbCast3: $tmdbCast3"
tmdbCast4=`echo "$tmdbCredits" | jq ".cast[4] | .name" | sed 's/"//g'`; echo "tmdbCast4: $tmdbCast4"
tmdbCast5=`echo "$tmdbCredits" | jq ".cast[5] | .name" | sed 's/"//g'`; echo "tmdbCast5: $tmdbCast5"
tmdbCast6=`echo "$tmdbCredits" | jq ".cast[6] | .name" | sed 's/"//g'`; echo "tmdbCast6: $tmdbCast6"
##### BUILD CAST XML LINES (-f runs) #####################################################
echo ""; echo "##### BUILD CAST XML LINES (-f runs) #####"
xmlCast0=''; if [ "$tmdbCast0" != 'null' ]; then xmlCast0="<dict><key>name</key><string>$tmdbCast0</string></dict>"; fi; echo "xmlCast0: $xmlCast0"
xmlCast1=''; if [ "$tmdbCast1" != 'null' ]; then xmlCast1="<dict><key>name</key><string>$tmdbCast1</string></dict>"; fi; echo "xmlCast1: $xmlCast1"
xmlCast2=''; if [ "$tmdbCast2" != 'null' ]; then xmlCast2="<dict><key>name</key><string>$tmdbCast2</string></dict>"; fi; echo "xmlCast2: $xmlCast2"
xmlCast3=''; if [ "$tmdbCast3" != 'null' ]; then xmlCast3="<dict><key>name</key><string>$tmdbCast3</string></dict>"; fi; echo "xmlCast3: $xmlCast3"
xmlCast4=''; if [ "$tmdbCast4" != 'null' ]; then xmlCast4="<dict><key>name</key><string>$tmdbCast4</string></dict>"; fi; echo "xmlCast4: $xmlCast4"
xmlCast5=''; if [ "$tmdbCast5" != 'null' ]; then xmlCast5="<dict><key>name</key><string>$tmdbCast5</string></dict>"; fi; echo "xmlCast5: $xmlCast5"
xmlCast6=''; if [ "$tmdbCast6" != 'null' ]; then xmlCast6="<dict><key>name</key><string>$tmdbCast6</string></dict>"; fi; echo "xmlCast6: $xmlCast6"



##### EXTRACT GUEST STARS FROM TMDB API RESULTS (-f runs) ################################
echo ""; echo "##### EXTRACT GUEST STARS FROM TMDB API RESULTS (-f runs) #####"
tmdbGuest0=`echo "$tmdbCredits" | jq ".guest_stars[0] | .name" | sed 's/"//g'`; echo "tmdbGuest0: $tmdbGuest0"
tmdbGuest1=`echo "$tmdbCredits" | jq ".guest_stars[1] | .name" | sed 's/"//g'`; echo "tmdbGuest1: $tmdbGuest1"
tmdbGuest2=`echo "$tmdbCredits" | jq ".guest_stars[2] | .name" | sed 's/"//g'`; echo "tmdbGuest2: $tmdbGuest2"
tmdbGuest3=`echo "$tmdbCredits" | jq ".guest_stars[3] | .name" | sed 's/"//g'`; echo "tmdbGuest3: $tmdbGuest3"
tmdbGuest4=`echo "$tmdbCredits" | jq ".guest_stars[4] | .name" | sed 's/"//g'`; echo "tmdbGuest4: $tmdbGuest4"
tmdbGuest5=`echo "$tmdbCredits" | jq ".guest_stars[5] | .name" | sed 's/"//g'`; echo "tmdbGuest5: $tmdbGuest5"
tmdbGuest6=`echo "$tmdbCredits" | jq ".guest_stars[6] | .name" | sed 's/"//g'`; echo "tmdbGuest6: $tmdbGuest6"
##### BUILD GUEST STAR XML LINES (-f runs) ###############################################
echo ""; echo "##### BUILD GUEST STAR XML LINES (-f runs) #####"
xmlGuest0=''; if [ "$tmdbGuest0" != 'null' ]; then xmlGuest0="<dict><key>name</key><string>$tmdbGuest0</string></dict>"; fi; echo "xmlGuest0: $xmlGuest0"
xmlGuest1=''; if [ "$tmdbGuest1" != 'null' ]; then xmlGuest1="<dict><key>name</key><string>$tmdbGuest1</string></dict>"; fi; echo "xmlGuest1: $xmlGuest1"
xmlGuest2=''; if [ "$tmdbGuest2" != 'null' ]; then xmlGuest2="<dict><key>name</key><string>$tmdbGuest2</string></dict>"; fi; echo "xmlGuest2: $xmlGuest2"
xmlGuest3=''; if [ "$tmdbGuest3" != 'null' ]; then xmlGuest3="<dict><key>name</key><string>$tmdbGuest3</string></dict>"; fi; echo "xmlGuest3: $xmlGuest3"
xmlGuest4=''; if [ "$tmdbGuest4" != 'null' ]; then xmlGuest4="<dict><key>name</key><string>$tmdbGuest4</string></dict>"; fi; echo "xmlGuest4: $xmlGuest4"
xmlGuest5=''; if [ "$tmdbGuest5" != 'null' ]; then xmlGuest5="<dict><key>name</key><string>$tmdbGuest5</string></dict>"; fi; echo "xmlGuest5: $xmlGuest5"
xmlGuest6=''; if [ "$tmdbGuest6" != 'null' ]; then xmlGuest6="<dict><key>name</key><string>$tmdbGuest6</string></dict>"; fi; echo "xmlGuest6: $xmlGuest6"



##### COMBINE CAST AND GUEST STARS XML LINES INTO XML BLOCK (-f runs) ####################
echo ""; echo "##### COMBINE CAST AND GUEST STARS XML LINES INTO XML BLOCK (-f runs) #####"
castBlock=''
if [ ! -z "$xmlCast0" ]; then castBlock="<key>cast</key>${newline}  <array>${newline}    $xmlCast0"; fi
if [ ! -z "$xmlCast1" ]; then castBlock="$castBlock${newline}    $xmlCast1"; fi
if [ ! -z "$xmlCast2" ]; then castBlock="$castBlock${newline}    $xmlCast2"; fi
if [ ! -z "$xmlCast3" ]; then castBlock="$castBlock${newline}    $xmlCast3"; fi
if [ ! -z "$xmlCast4" ]; then castBlock="$castBlock${newline}    $xmlCast4"; fi
if [ ! -z "$xmlCast5" ]; then castBlock="$castBlock${newline}    $xmlCast5"; fi
if [ ! -z "$xmlCast6" ]; then castBlock="$castBlock${newline}    $xmlCast6"; fi
if [ ! -z "$xmlGuest0" ]; then castBlock="$castBlock${newline}    $xmlGuest0"; fi
if [ ! -z "$xmlGuest1" ]; then castBlock="$castBlock${newline}    $xmlGuest1"; fi
if [ ! -z "$xmlGuest2" ]; then castBlock="$castBlock${newline}    $xmlGuest2"; fi
if [ ! -z "$xmlGuest3" ]; then castBlock="$castBlock${newline}    $xmlGuest3"; fi
if [ ! -z "$xmlGuest4" ]; then castBlock="$castBlock${newline}    $xmlGuest4"; fi
if [ ! -z "$xmlGuest5" ]; then castBlock="$castBlock${newline}    $xmlGuest5"; fi
if [ ! -z "$xmlGuest6" ]; then castBlock="$castBlock${newline}    $xmlGuest6"; fi
if [ ! -z "$castBlock" ]; then castBlock="$castBlock${newline}  </array>"; fi
echo "$castBlock"



##### EXTRACT WRITER FROM TMDB API RESULTS (-f runs) #####################################
echo ""; echo "##### EXTRACT WRITER FROM TMDB API RESULTS (-f runs) #####"
tmdbCrewCnt=`echo "$tmdbCredits" | jq '.crew | length'`	
tmdbCrewLoop='0'
while [ "$tmdbCrewLoop" -lt "$tmdbCrewCnt" ]
do
	tmdbCrew=`echo "$tmdbCredits" | jq ".crew[$tmdbCrewLoop] | .job" | sed 's/"//g'`; #echo "$tmdbCrew"
	if [ "$tmdbCrew" == "Writer" ]; then tmdbWriter0=`echo "$tmdbCredits" | jq ".crew[$tmdbCrewLoop] | .name" | sed 's/"//g'`; echo "tmdbWriter0: $tmdbWriter0"; fi
	let tmdbCrewLoop++
done
##### BUILD WRITER XML LINES (-f runs) ###################################################
echo ""; echo "##### BUILD WRITER XML LINES (-f runs) #####"
xmlWriter0=''; if [ ! -z "$tmdbWriter0" ]; then xmlWriter0="<dict><key>name</key><string>$tmdbWriter0</string></dict>"; fi; echo "xmlWriter0: $xmlWriter0"
##### BUILD WRITER XML BLOCK (-f runs) #####
echo ""; echo "##### BUILD WRITER XML BLOCK #####"
writerBlock=''
if [ ! -z "$xmlWriter0" ]; then writerBlock="<key>screenwriters</key>${newline}  <array>${newline}    $xmlWriter0"; fi 
if [ ! -z "$writerBlock" ]; then writerBlock="$writerBlock${newline}  </array>"; fi
echo "$writerBlock"



##### EXTRACT DIRECTOR FROM TMDB API RESULTS (-f runs) ###################################
echo ""; echo "##### EXTRACT DIRECTOR FROM TMDB API RESULTS (-f runs) #####"
tmdbCrewCnt=`echo "$tmdbCredits" | jq '.crew | length'`	
tmdbCrewLoop='0'
tmdbDirector0=''
while [ "$tmdbCrewLoop" -lt "$tmdbCrewCnt" ]
do
	tmdbCrew=`echo "$tmdbCredits" | jq ".crew[$tmdbCrewLoop] | .job" | sed 's/"//g'`; #echo "$tmdbCrew"
	if [ "$tmdbCrew" == "Director" ]; then tmdbDirector0=`echo "$tmdbCredits" | jq ".crew[$tmdbCrewLoop] | .name" | sed 's/"//g'`; echo "tmdbDirector0: $tmdbDirector0"; fi
	let tmdbCrewLoop++
done
##### BUILD DIRECTOR XML LINES (-f lines) ################################################
echo ""; echo "##### BUILD DIRECTOR XML LINES (-f lines) #####"
xmlDirector0=''; if [ ! -z "$tmdbWriter0" ]; then xmlDirector0="<dict><key>name</key><string>$tmdbDirector0</string></dict>"; fi; echo "xmlDirector0: $xmlDirector0"

##### BUILD DIRECTOR XML BLOCK #####
echo ""; echo "##### BUILD DIRECTOR XML BLOCK #####"
directorBlock=''
if [ ! -z "$xmlDirector0" ]; then directorBlock="<key>directors</key>${newline}  <array>${newline}    $xmlDirector0"; fi 
if [ ! -z "$directorBlock" ]; then directorBlock="$directorBlock${newline}  </array>"; fi
echo "$directorBlock"



##### BUILD FINAL CAST/CREW/STUDIO XML BLOCK (-f runs) ###################################
echo ""; echo "##### BUILD FINAL CAST/CREW/STUDIO XML BLOCK (-f runs) #####"
castCrewXml="<!DOCTYPE plist PUBLIC \"-//Apple Computer//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
  $castBlock
  $writerBlock
  $directorBlock
</dict>
</plist>"
#echo "$castCrewXml"


##### REMOVE EMPTY LINES IN FINAL CAST/CREW/STUDIO XML BLOCK (-f runs) #########################
echo ""; echo "##### REMOVE EMPTY LINES IN FINAL CAST/CREW/STUDIO XML BLOCK (-f runs) #####"
castCrewXmlb=''
for line in "${castCrewXml}"
do
	line=`echo "$line" | sed '/^[[:space:]]*$/d'`
	castCrewXmlb="$castCrewXmlb $line"
done
echo "$castCrewXmlb"
echo ""; echo "Done removing empty lines..."


##### COUNT LINES IN FINAL XML BLOCK, MAKE BLANK IF NOT ENOUGH DATA (-f runs) #####
echo ""; echo "##### COUNT LINES IN FINAL XML BLOCK, MAKE BLANK IF NOT ENOUGH DATA (-f runs) #####"
xmlLineCnt=`echo -n "$castCrewXmlb" | grep -c '^'`
if [ "$xmlLineCnt" -lt '6' ]; then castCrewXmlb=''; echo "No cast, guest star, writer, or director data, making XML empty"; fi
echo ""; echo "Done checking final XML block..."


##### TMDB API: DOWNLOAD EPISODE SPECIFIC ART FILE (-f runs) #############################
echo ""; echo "##### TMDB API: DOWNLOAD EPISODE SPECIFIC ART FILE (-f runs) #####"
wget -O "$artFile" "https://www.themoviedb.org/t/p/original/$tmdbStill_path"
echo "Done downloading art file..."


fi
##########################################################################################
##### END FULL RUNS ######################################################################



if [ "$liter" -eq '1' ]; then
	##### TMDB API: DOWNLOAD SEASON SPECIFIC(NOT EPISODE) ART FILE (-l runs) #################
	echo ""; echo "##### TMDB API: DOWNLOAD SEASON SPECIFIC(NOT EPISODE) ART FILE (-l runs) #####"
	tmdbSeasonArt=`echo "$tmdbSeriesGenre" | jq ".seasons[$extractShowSeason] | .poster_path" | sed 's/"//g'`;		# echo "tmdbSeasonArt: $tmdbSeasonArt"
	echo ""
	wget -O "$artFile" "https://www.themoviedb.org/t/p/original$tmdbSeasonArt"
	echo "Done downloading art file..."
fi



##### SAFETY CHECKS BEFORE WRTIING WITH ATOMIC (all flags) #####
echo ""; echo "##### SAFETY CHECKS BEFORE WRTIING WITH ATOMIC (all flags) #####"
if [ "$fullr" -eq '1' ]; then if [ -z "$castCrewXmlb" ]; then echo "No cast/guest/writer/director found, quitting"; echo ""; exit; fi; fi
if [ "$fullr" -eq '1' ]; then if [ -z "$tmdbEpisode_number" ]; then echo "TMDB episode number not found, quitting"; echo ""; exit; fi; fi
if [ "$fullr" -eq '1' ]; then if [ -z "$tmdbOverview" ]; then echo "TMDB overviw not found, quitting"; echo ""; exit; fi; fi
if [ ! -f "$artFile" ]; then echo "No poster art found, quitting"; echo ""; exit; fi
if [ ! -d "$itunesDir" ]; then echo "Destination path not found, quitting"; echo ""; exit; fi
if [ "$dryr" -eq '1' ]; then echo "Dry run option was set, quitting"; echo ""; exit; fi
echo "Passed safety checks, proceeding..."


##### ATOMIC: CLEAR CURRENT ATOMS AND ART IN MEDIA FILE (all flags) ##################
if [ "$dryr" -ne '1' ]; then
	echo ""; echo "##### ATOMIC: CLEAR CURRENT ATOMS AND ART IN MEDIA FILE (all flags) #####"
	AtomicParsley "$curMedia" --overWrite --metaEnema --artwork "REMOVE_ALL"
	echo ""; echo "Done clearing atoms and art with atomic..."
fi




##########################################################################################
##### FULL RUNS (-f) #####################################################################

if [ "$fullr" -eq '1' ]; then
if [ "$repor" -eq '0' ]; then

##### BUILD COMMENT (-f runs) ############################################################
echo ""; echo "##### BUILD COMMENT (-f runs) #####"
movieComment="Source: $OrginalSource
Extracter: $diskExtracter
Encoder: $fileEncoder
Who: $whoEncode
Vid 0:0 $movieVidCodec $movieVidRate/s Res:$movieRes(HD:$hdState)
$audOneAll
$audTwoAll
TMDB ID: $tmdbShowId
Script: $ver"
echo "$movieComment"

##### ATOMIC: WRITE ATOMS AND ART TO FILE (-f runs) ######################################
echo ""; echo "##### ATOMIC: WRITE ATOMS AND ART TO FILE (-f runs) #####"
AtomicParsley "$curMedia" \
--overWrite \
--stik "TV Show" \
--encodingTool "$fileEncoder" \
--encodedBy "$whoEncode" \
--hdvideo "$hdState" \
--year "$tmdbAirDate" \
--description "$tmdbOverview" \
--longdesc "$tmdbOverview" \
--TVShowName "$tmdbShowName" \
--TVEpisode "$tmdbShowId" \
--TVSeasonNum "$tmdbSeason_number" \
--TVEpisodeNum "$tmdbEpisode_number" \
--comment "$movieComment" \
--artist "$tmdbDirector0" \
--contentRating "$tmdbRatingUS" \
--genre "$tmdbGenre0" \
--artwork "$artFile" \
--rDNSatom "$castCrewXmlb" name=iTunMOVI domain=com.apple.iTunes
echo ""; echo "Done wrting atoms and art to file..."

fi
fi

##### END FULL RUNS (-f) #################################################################








##########################################################################################
##### REPROCESS RUNS (-f -r) #####################################################################

if [ "$repor" -eq '1' ]; then

##### BUILD COMMENT (-f -r runs) ############################################################
echo ""; echo "##### BUILD COMMENT (-r runs) #####"
movieComment="Source: $OrginalSource
Who: $whoEncode
Vid 0:0 $movieVidCodec $movieVidRate/s Res:$movieRes(HD:$hdState)
$audOneAll
$audTwoAll
TMDB ID: $tmdbShowId
Script: $ver"
echo "$movieComment"

##### ATOMIC: WRITE ATOMS AND ART TO FILE (-f -r runs) ######################################
echo ""; echo "##### ATOMIC: WRITE ATOMS AND ART TO FILE (-f runs) #####"
AtomicParsley "$curMedia" \
--overWrite \
--stik "TV Show" \
--encodedBy "$whoEncode" \
--hdvideo "$hdState" \
--year "$tmdbAirDate" \
--description "$tmdbOverview" \
--longdesc "$tmdbOverview" \
--TVShowName "$tmdbShowName" \
--TVEpisode "$tmdbShowId" \
--TVSeasonNum "$tmdbSeason_number" \
--TVEpisodeNum "$tmdbEpisode_number" \
--comment "$movieComment" \
--artist "$tmdbDirector0" \
--contentRating "$tmdbRatingUS" \
--genre "$tmdbGenre0" \
--artwork "$artFile" \
--rDNSatom "$castCrewXmlb" name=iTunMOVI domain=com.apple.iTunes
echo ""; echo "Done wrting atoms and art to file..."

fi

##### END REPROCESS RUNS (-f -r) #################################################################








##########################################################################################
##### LITE RUNS (-l)  ####################################################################

if [ "$liter" -eq '1' ]; then

##### BUILD COMMENT (-l runs) #####
echo ""; echo "##### BUILD COMMENT (-l runs) #####"
movieComment="Source: $OrginalSource
Who: $whoEncode
Vid 0:0 $movieVidCodec $movieVidRate/s Res:$movieRes(HD:$hdState)
$audOneAll
$audTwoAll
TMDB ID: $tmdbShowId
Script: $ver"
echo "$movieComment"

##### ATOMIC: WRITE ATOMS TO FILE (-l runs) ##### ########################################
echo ""; echo "##### ATOMIC: WRITE ATOMS TO FILE (-l runs) #####"
AtomicParsley "$curMedia" \
--overWrite \
--stik "TV Show" \
--encodedBy "$whoEncode" \
--hdvideo "$hdState" \
--TVShowName "$extractShowNameA" \
--TVSeasonNum "$extractShowSeason" \
--TVEpisodeNum "$extractShowEpisode" \
--comment "$movieComment" \
--genre "$tmdbGenre0" \
--artwork "$artFile"
echo ""; echo "Done wrting atoms and art to file..."

fi

##### END LITE RUNS (-l) #################################################################






##### MOVE MEDIA FILE INTO DESTINATION DIR (all flags) ###################################
echo ""; echo "##### MOVE MEDIA FILE INTO DESTINATION DIR (all flags) #####"
sleep 3
finalDestDur="$itunesDir$fileMedia"
echo "Moving finished file to $finalDestDur"
mv "$curMedia" "$itunesAutoAddDest"
echo "Done moving movie file..."


##### DELETE DOWNLOADED ART FILE (all flags) #############################################
echo ""; echo "##### DELETE DOWNLOADED ART FILE (all flags) #####"
rm "$artFile"
echo "Done deleting art file..."
echo ""


##### END PRIMARY LOOP #####
done

