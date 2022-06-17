# Atomic-L0r3-TV
 BASH script that embeds .m4v files with metadata and art from themoviedb.org API using AtomicParsley

WHAT IS THIS SCRIPT?  
	- Reads a directory of TV show files (must be .m4v)  
	- Embeds data and art from themoviedb.org API (TMDB) into the files  
	- Note: This is built with too many comments so others can make their own version easily  
  
  
USING FLAGS:  
For new files, when episode number is accurate:			-f (full)  
For new files, when episode number is not verified:		-l (lite)  
Reprocessing files when episode number is accurate:		-f -r (full and reprocess)  
Dry run:													-d  
  
  
-d: DRY RUN  
		Wont write to file  
		Can be used with -f or -l  
  
-f: FULL RUN  
		Use when the episode number is accurate (fetches/embeds season and episode specific data)  
		WRITES COMMENTS:  
			- Source: $OrginalSource  
			- Extracter: $diskExtracter  
			- Encoder: $fileEncoder  
			- Who: $whoEncode  
			- Vid 0:0 $movieVidCodec $movieVidRate/s Res:$movieRes(HD:$hdState)  
			- $audOneAll  
			- $audTwoAll  
			- TMDB: $tmdbShowId  
			- Script: $ver  
		WRITES ATOMS:  
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
			--rDNSatom "$castCrewXml" name=iTunMOVI domain=com.apple.iTunes
  
-r: REPROCESS RUN  
		Use with -f for media that the episode is accurate, but the extractor and encoder are unknown  
		WRITES COMMENTS:  
			- Source: $OrginalSource  
			- Who: $whoEncode  
			- Vid 0:0 $movieVidCodec $movieVidRate/s Res:$movieRes(HD:$hdState)  
			- $audOneAll  
			- $audTwoAll  
			- TMDB ID: $tmdbShowId  
			- Script: $ver"  
		WRITES ATOMS:  
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
  
-l: LITE RUN  
		Use when the episode number has NOT been verified (embeds only season specific data)  
		WRITES COMMENT:  
			- Source: $OrginalSource  
			- Who: $whoEncode  
			- Vid 0:0 $movieVidCodec $movieVidRate/s Res:$movieRes(HD:$hdState)  
			- $audOneAll  
			- $audTwoAll  
			- TMDB: $tmdbShowId  
			- Script: $ver  
		WRITES ATOMS  
			--stik "TV Show" \
			--encodedBy "$whoEncode" \
			--hdvideo "$hdState" \
			--TVShowName "$extractShowNameA" \
			--TVSeasonNum "$extractShowSeason" \
			--TVEpisodeNum "$extractShowEpisode" \
			--comment "$movieComment" \
			--genre "$tmdbGenre0" \
			--artwork "$artFile"


TESTED FILE NAME FORMAT EXAMPLES:  
	The X-Files s02x11.m4v  
	The X-Files s02x11 Excelsis Dei.m4v  


### DEV AND TEST ###
  
SCRIPT HAS BEEN FULLY TESTED UNDER:  
	- MacOS 11.6.6 and 12.3.1  
	- wget 1.21.3  
	- jq 1.6  
	- ffmpeg 5.0.1  
	- AtomicParsley 20210715.151551.e7ad03a  

DISPLAY OF DATA TESTED WITH PLAYERS:  
	- Apples TV.app (tested on 1.2.3.56)  
	- AppleTV devices (tested on gen2 and gen3)  
	- iTunes on Mac (last version produced)  
	- iTunes on Windows (last version produced)  
  
  
### CHANGE LOG ###
  
v5.8.3  
	xxxxxxxx  
  
v5.8.2  
	Added what run flags were used to comment  
	Added additional safety check for null TMDB show overview(description)  
  
v5.8.1  
	Minor console readability updates  
	Fixed bug where comments for non -r runs where showing in console  
	Fixed bug reading the new -r flag  
  
v5.8.0  
	Added flag and code for reprocess (-r) runs  
	Tested enabling running with files that have episode names in them, successful  
  
v5.7.9  
	Calling this the new STABLE and creating next version  
  
v5.7.8  
	In comments changed "TMDB" to "TBDB ID"  
	Safety for art was triggered during lite runs, moved -l art wget to before safety checks  
	Minor changes to safeties, to work with new flag system  
  
v5.7.7   
	If no cast, guest stars, director, or writer, then final XML block is blanked  
	Improved null detection for cast  
	Improved null detection for guest stars  
	Added removal of blank lines from final XML for cases where TMDB doesnt have data  
	Add check for -f and -l being used at the same time  
  
v5.7.6  
	Updated documentation for new flags  
	MAJOR rewrite of flag system, had become convoluted over time  
	Cleaned up all comments  
	Added tail -1 to audio extraction for reliability under various conditions  
  
v5.7.5  
	Improved audio stream extraction  
	Improved audio stream console output  
  
v5.7.4  
	Updated video stream codec extraction to be relyable under more conditions  
	Updated video stream rate extraction to be relyable under more conditions  
	Updated video stream resolution extraction to be relyable under more conditions  
	Stopped -m comment from showing durung -o runs  
	Added pre-deleting of any existing art file  
	In comments changed "ScriptVer" to "Script"  
  
v5.7.3  
	Added "Source" back to -m comments  
	Moved art file location to /tmp  
	Added full atom purge for all run (except -d), removed atoms that wrote nulls  
  
v5.7.2  
	For -m runs, added atoms with null value, as TV Shows should not have these  
		--album
		--albumArtist
		--composer
		--grouping
	Reduced sleep before moving file to destination from 4 to 3 (due to upgrade in fast storage and CPU)  
  
v5.7.1  
	Very minor updates to console visula output  
	Improved null detection for cast and guest star XML line creation lines  
	Fixed bug with atoms being cleared during -d runs  
  
v5.7.0  
	Declaring this one stable and creating next version  
  
v5.6.9  
	Fixed extra line break in -m comments  
	Decided not to add producers, as TMBD has production company but not producer humans  
  
v5.6.8 (The one about -m improvements)  
	Changed -m runs to have an "if -m" for each section for easier future changes  
	Added run flag info to each section  
	Prints flag options if -p was not used  
  
v5.6.7 (The one about new flags)  
	Added -p flag as a safety feature (AKA did you think about flags before running?)  
	Added -o flag for minimal comments  
  
v5.6.6 (The one about comments for -m runs)  
	Built separate comment for -m runs  
	-m comment: removed source, extractor, and encoder strings  
  
v5.6.5 (The one about director fixes)  
	Removed writing encoding tool atom to -m runs  
	Director (artist) atom was set to "$tmdbDirector" when it should be "$tmdbDirector0"  
	Fixed Director in except final XML block  
	Removed orphaned reference to "BACKUP FILE"  
  
v5.6.4  
	Encoder atom string was incorrect, fixed  
	Improved notes in the "user settable" area  
	Moved the definition of the art file name out of the "user settable" area  
  
v5.6.3 (The one about better XML)  
	Changed cast extraction for better null detection  
	Added feature to build block of cast, to be used in final XMLs  
	Changed guest star extraction for better null detection  
	Added feature to build block of guest star, to be used in final XML  
	Changed the XML block to use the new cast and guest XML blocks  
	Changed writer extraction for better null detection  
	Added feature to build block of writers, to be used in final XMLs  
	Changed director extraction for better null detection  
	Added feature to build block of directors, to be used in final XMLs  
	Add XML <key> and <array> to cast block builder so final XML wont be blank if there is none  
	Add XML <key> and <array> to guest star block builder so final XML wont be blank if there is none  
	Add XML <key> and <array> to writer block builder so final XML wont be blank if there is none  
	Add XML <key> and <array> to director block builder so final XML wont be blank if there is none  
	Fixed -d runs showing "DOWNLOAD SEASON SPECIFIC (NOT EPISODE) ART FILE FOR -m RUNS"  
  
v5.6.2 (The one about declaring a stable version)  
	This version can be considered very polished, calling this "stable" and making v5.6.3  
  
v5.6.1 (The one about making comments nicer)  
	Removed "/s" from video bit rate in comment  
	Removed duration from comment  
	Removed "Rate" from audio in comment  
	Moved "who encoded" to its own line in comment  
	Changed "Original" to "Source" in comment  
  
v5.6.0 (The one about the episode number bug)  
	Fixed issue with file season number not extracting correctly when episode name had an "x" in it  
	$extractEpisodeName had no purpose, commented out (saving for potential use later)  
	Moved $ver higher in the script to display properly in launch banner  
  
v5.5.9 (The one about very little)  
	Removed Audio Hz from comments to save text space  
	Added user settable "extractor" string  
  
v5.5.8 (The one about making -m awsome)  
	Removed writing comments from -m runs  
	Added sesaon specific (not episode specific) art fetching and embeding to -m runs  
	Added genre fetching and embeding back to -m runs  
	Added skip of clearing current atoms when -m is used  
	Moved notes and change logs out of script, to its own document (was too big)  
  
v5.5.7 (The one about genre)  
	Added API call to get show genre and write genre atom  
  
v5.5.6 (The one about a -m improvement)  
	Minimal install flag (-m) now skips making API calls to TMDB  
  
v5.5.5 (The one about dependency improvements)  
	Made dependency check system more robust  
	Added to the notes section, describing what the script does, and -m flag details  
	Further updated set of atoms written when -m flag is used  
  
v5.5.4 (The one about minimal atom writing)  
	Added launch flag for minimal atom writing (-m flag)  
  
v5.5.3 (The one about the art file path)  
	Added variable for setting media art file path instead of hard coded  
  
v5.5.2 (The one about fixing a bunch of minor things 'n stuff)  
	New HD atom writing  
	Changed atom writing from --TVEpisode "$tmdbName" to --TVEpisode "$tmdbShowId"  
	Added safety check for destination path availability  
	Altered variable so full path to destination is in "user settable" area  
	More console output improvement  
	More commenting improvements  
	Removed unneeded "newline" references in code  
	Cleaned up the output "comment" further  
  
v5.5.1 (The one about being the prettiest girl at the party)  
	Replaced many old references to 'iTunes' with more generic references  
	Added more comments to console output  
	Removed unused line left over from movie script  
	Removed unneeded console output  
	Removed testing code  
	Removed comments used for dev purposes  
	Removed genre related placeholder code (TMBD doesnt list genere for shows)  
	Removed milliseconds from extracted ffmpeg duration  
  
v5.5.0 (The one about the future)  
	Removed "Producer" related code (TMBD doesnt list producers for episodes)  
	Added dry-run option (-d launch argument)  
	Added safety check for data before proceeding with writing to file  
	Resolved duration issue (now only looks at last line of grep results)  
	Removed support for MacOS < 12.3.1  
	Removed support for fmpeg < 5.0.1  
	Removed support for AtomicParsley < 0210715.151551.e7ad03a  
  
v5.0.3 (The one that not much happened)  
	Added notes section  
	Improved announcement banner  
  
v5.0.2 (The one about reliability improvements)  
	Removed ffmpeg extracting media stream 3 and 4 data  
	Improved progress output for humans  
	Created show name with spaces replaced with dashes for API call  
	Fixed media year extraction  
	Improved cast extraction method  
	Improved guest star extraction method  
	Fixed extracting media length for use in comments  

v5.0.1 (The one about dependency paths)  
	Added auto finding paths to dependencies for different MacOS versions  
  
v5.0.0 (The one about improving this project again after a couple years)  
	Moved from 4.x versioning to 5.x  
  
  
### BUG TODO ####
No known bugs at the moment  
  
  
### NEW FEATURE IDEAS ####
If TBDB has lenght for TV shows (it does for movies) compainr that to the files lenght and stop if not ~match  
Saftey stop if no season number  
Safety stop if no episode number  
When dry run, display show name and TMDB ID before quitting
