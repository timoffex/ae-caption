#!/bin/bash

# Exit if any command fails
set -e

directory=`dirname $0`

if [ ! -e transcript.txt ]; then
    $directory/add_timestamps.rb $directory/just_text.txt 5 >$directory/transcript.txt
fi

$directory/jsonify_transcript.rb $directory/transcript.txt $@ >/tmp/transcribe.jsx
cat $directory/transcribe_base.jsx >> /tmp/transcribe.jsx

exit 0

osascript -l JavaScript -e "
ae = Application('Adobe After Effects 2022');
ae.activate();
ae.doscriptfile('/tmp/transcribe.jsx');
"
