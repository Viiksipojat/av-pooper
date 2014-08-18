# av-pooper

re-POOPS UR AUDIO & VIDEO FILES into your CURRENT directory.

## Prerequisites

	brew reinstall ffmpeg --with-libvpx --with-theora --with-libvorbis
	brew install vorbis-tools lame faac

## Usage

	./av-pooper.sh "formats" infiles ["formats" infiles] ...

### Example

	./av-pooper.sh "webm mp4" hotty.mov swimmy.mov "ogg m4a" hooters.wav loopers.wav

produces

	hotty.webm	hotty.mp4
	swimmy.webm	swimmy.mp4
	hooters.ogg	hooters.m4a
	loopers.ogg	loopers.m4a
