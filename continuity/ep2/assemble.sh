#!/bin/bash
# usage: assemble.sh <outname> <clip1> <clip2> ...
cd ~/workspace/ep1_full
OUT=$1; shift
mkdir -p norm
LIST=norm/${OUT}_list.txt; : > $LIST
i=0
for c in "$@"; do
  i=$((i+1))
  N=norm/${OUT}_$i.mp4
  ffmpeg -y -v error -i ${c}_raw.mp4 -vf "scale=720:1280:flags=lanczos,fps=24,setsar=1,hqdn3d=2:1.5:3:2.2" -af "aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo" -c:v libx264 -crf 18 -pix_fmt yuv420p -c:a aac -b:a 160k $N || exit 1
  echo "file '$PWD/$N'" >> $LIST
done
ffmpeg -y -v error -f concat -safe 0 -i $LIST -c copy norm/${OUT}_cat.mp4 || exit 1
ffmpeg -y -v error -i norm/${OUT}_cat.mp4 -af loudnorm=I=-16:TP=-1.5:LRA=11 -c:v copy -c:a aac -b:a 160k ${OUT}.mp4 || exit 1
ffprobe -v error -show_entries format=duration -show_entries stream=codec_type,width,height,r_frame_rate -of default=noprint_wrappers=1 ${OUT}.mp4
ffmpeg -i ${OUT}.mp4 -af ebur128 -f null - 2>&1 | grep -A2 "Summary" | head -6
