#!/bin/bash
#
# A script to do p&p HLS to MSL4 using FFmpeg
#
# Jason Lim (c) 2019
# jason.sslim@gmail.com
#

# Origin Source
inputURL="http://0.0.0.0:8080/master.m3u8"

# MSL4 Stream ID
msl4id="12345"

# MSL4 Event Name
eventName="testEvent"

# Log directory
logFile="/var/log/$eventName.log"

# FFmpeg pull from Origin and push to MSL4
pullNpush () {
    ffmpeg -nostdin -reconnect_streamed 1 -reconnect_delay_max 300 \
        -i $inputURL \
        -s:v:1 854x480 -b:v:1 1200k \
        -s:v:0 640x360 -b:v:0 800k \
        -b:a:1 96k -ac 2 \
        -b:a:0 96k -ac 2 \
        -af "volume=15dB" \
        -map 0:v -map 0:a \
        -map 0:v -map 0:a \
        -var_stream_map "v:0,a:0 v:1,a:1" \
        -aspect 16:9 -master_pl_name index.m3u8  -r 25\
        -g 50 -method POST -http_persistent 1 \
        -hls_time 6 -hls_list_size 6 -segment_list_flags +live -write_empty_segments 1 \
        -start_number $(date "+%s") -f hls http://p-ep$msl4id.i.akamaientrypoint.net/$msl4id/$eventName/index_%v_.m3u8
}

# Create log directory if not exist
logCheck () {
    if [[ ! -e $logFile ]]; then
        mkdir -p $HOME/var/log/
        touch $logFile
        chmod 0600 $logFile
    fi
}

#main
main () {
    echo "FFmpeg crashed previously, restarting ffmpeg..." >> $logFile
    logCheck
    pullNpush >> $logFile 2>&1
}

until main;
do
    #restart ffmpeg upon error
    echo "FFmpeg crashed previously, restarting ffmpeg..."
    sleep 2
done
