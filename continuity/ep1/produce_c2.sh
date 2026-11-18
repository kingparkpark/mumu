#!/bin/bash
cd ~/workspace/ep1_full
W=$HOME/workspace/ep1_remake/world_master.png
D=$HOME/workspace/user/media_library/image/upload-4.jpg
run() { name=$1; feeds=$2;
  python3 gen.py $name "$feeds" || { echo "GENFAIL $name" >> audit_c2.txt; return; }
  ffmpeg -y -v error -sseof -0.1 -i ${name}_raw.mp4 -frames:v 1 ${name}_last.png
  ffmpeg -y -v error -i ${name}_raw.mp4 -vf "fps=2,scale=360:640,tile=5x4:padding=2:margin=2" -frames:v 1 ${name}_tiles.png
  ffmpeg -y -v error -i ${name}_raw.mp4 -vn -ar 16000 -ac 1 ${name}.wav
  echo "== $name ==" >> audit_c2.txt
  ~/workspace/laopu_ep1/asr_venv/bin/python asr_words.py ${name}.wav 2>/dev/null | tail -4 >> audit_c2.txt
}
run s13a2 "$PWD/delivery.png,$W,$D"
run s13b2 "$PWD/delivery.png,$W,$D,$PWD/s13a2_last.png"
run s16r "$PWD/tower.png,$W,$D"
echo ALLDONE >> audit_c2.txt
