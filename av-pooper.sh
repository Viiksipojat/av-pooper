#!/bin/bash
# re-POOPS UR AUDIO & VIDEO FILES into your CURRENT directory
# TODO: -y overwrite, check-for-dependencies

# USAGE: $0 "formats" infiles ["formats" infiles] ...

# EXAMPLE: $0 "webm mp4" hotty.mov swimmy.mov "ogg mp3" hooters.wav loopers.wav
# → hotty.webm, hotty.mp4, swimmy.webm, swimmy.mp4, hooters.ogg, hooters.mp3, loopers.ogg, loopers.mp3

# NOTE: requires {ffmpeg, libvpx, libvorbis, libtheora} for VIDEO & {vorbis-tools, lame, faac} for AUDIO
# $ brew reinstall ffmpeg --with-libvpx --with-theora --with-libvorbis
# $ brew install vorbis-tools lame faac

# GLOBAL PARAMETERS
BITRATE_VIDEO=4000 # kbps
BITRATE_AUDIO=140 # kbps
RESOLUTION_X=1280 # y is auto-scaled preserving aspect ratio
X264Q=23 # default: 23 (lower better), leave empty to use BITRATE_VIDEO
VPXQ=20 # default: 10 (lower better), BITRATE_VIDEO becomes MAXIMUM bitrate
VORBISQ=5 # ~160 kbps
FAACQ=120 # ~140 kbps

# ENCODER-SPECIFIC PARAMETERS
# SIVUHUOMIO: -c:a vorbis on VÄÄRIN, re: http://www.hydrogenaudio.org/forums/index.php?showtopic=81600
ffmpeg_params="-b:v ${BITRATE_VIDEO}k -b:a ${BITRATE_AUDIO}k -vf scale=${RESOLUTION_X}:-1 -threads 4"
# BTW. avconvert & afconvert come from osx developer tools. w/ avconvert viddy bitrate gets too high.
avconvert_params="-p PresetAppleM4V720pHD -vdr ${BITRATE_VIDEO}000 -adr ${BITRATE_AUDIO}000 -tw $RESOLUTION_X"
afconvert_params="-d aac -s 1 -b ${BITRATE_AUDIO}000"
oggenc_params="-q $VORBISQ"
lame_params="-h --abr $BITRATE_AUDIO --nohist"
faac_params="-q $FAACQ"

outdir=.

for in in "$@"; do

	[ ! -e "$in" ] && {
		formats=$in
		continue
	}

	inext=${in##*.}
	base=$(basename "$in" .$inext)
	# dir=$(dirname $in)

	for outext in $formats; do
		out="$outdir/$base.$outext"
		echo "******************************** $in → $out"
		set -x
		case $outext in
			ogv)
				# DEFAULTS -c:v libtheora -c:a libvorbis
				ffmpeg -i "$in" $ffmpeg_params "$out"
				;;
			webm)
				ffmpeg -i "$in" $ffmpeg_params ${VPXQ:+-crf} $VPXQ "$out"
				;;
			mp4)
				# https://trac.ffmpeg.org/ticket/2115
				# http://gpac.wp.mines-telecom.fr/mp4box/#cont_deli
				# http://superuser.com/questions/438390/creatingmp4-videos-ready-forhttp-streaming
				# https://trac.ffmpeg.org/wiki/Encode/H.264#AppleQuicktime
				ffmpeg -i "$in" $ffmpeg_params ${X264Q:+-crf} $X264Q -movflags faststart -pix_fmt yuv420p "$out"
				;;
			# TESTING COLOR SPACE / PROFILE / MATRIX ??!?
			mp4-bt709)
				ffmpeg -i "$in" $ffmpeg_params -x264opts colorprim=bt709:transfer=bt709:colormatrix=smpte170m "$out"
				;;
			mp4-avconvert)
				avconvert -v -prog $avconvert_params -s "$in" -o "$out"
				;;
			wav)
				ffmpeg -i "$in" "$out"
				;;
			ogg)
				oggenc $oggenc_params -o "$out" "$in"
				;;
			mp3)
				lame $lame_params "$in" "$out"
				;;
			m4a)
				faac $faac_params -o "$out" "$in" \
				|| ffmpeg -i "$in" $ffmpeg_params "$out"
				;;
			m4a-afconvert)
				# BTW. afconvert also comes from osx developer tools.
				afconvert -v $afconvert_params "$in" "$out"
				;;
			jpg)
				# outputs the first frame of the viddy
				# mainly useful for making poster images for the web vids
				ffmpeg -i "$in" -vframes 1 "$out"
				;;
			*)
				echo "don't know what to do with $outext"
		esac
		set +x
	done
done
