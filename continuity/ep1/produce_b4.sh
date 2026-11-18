#!/bin/bash
cd ~/workspace/ep1_full
W=$HOME/workspace/ep1_remake/world_master.png
D=$HOME/workspace/user/media_library/image/upload-4.jpg
run() { name=$1; feeds=$2;
  python3 gen.py $name "$feeds" || { echo "GENFAIL $name" >> audit_b4.txt; return; }
  ffmpeg -y -v error -sseof -0.1 -i ${name}_raw.mp4 -frames:v 1 ${name}_last.png
  ffmpeg -y -v error -i ${name}_raw.mp4 -vf "fps=2,scale=360:640,tile=5x4:padding=2:margin=2" -frames:v 1 ${name}_tiles.png
  ffmpeg -y -v error -i ${name}_raw.mp4 -vn -ar 16000 -ac 1 ${name}.wav
  echo "== $name ==" >> audit_b4.txt
  ~/workspace/laopu_ep1/asr_venv/bin/python asr_words.py ${name}.wav 2>/dev/null | tail -4 >> audit_b4.txt
}
run s02b4 "$PWD/noodle.png,$W,$D,$PWD/s02a2_last.png"
run s05d "$W,$D"
echo ALLDONE >> audit_b4.txt
