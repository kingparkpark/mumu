#!/bin/bash
cd ~/workspace/ep1_full
W=$HOME/workspace/ep1_remake/world_master.png
D=$HOME/workspace/user/media_library/image/upload-4.jpg
run() { name=$1; feeds=$2;
  python3 gen.py $name "$feeds" || { echo "GENFAIL $name" >> audit_c.txt; return; }
  ffmpeg -y -v error -sseof -0.1 -i ${name}_raw.mp4 -frames:v 1 ${name}_last.png
  ffmpeg -y -v error -i ${name}_raw.mp4 -vf "fps=2,scale=360:640,tile=5x4:padding=2:margin=2" -frames:v 1 ${name}_tiles.png
  ffmpeg -y -v error -i ${name}_raw.mp4 -vn -ar 16000 -ac 1 ${name}.wav
  echo "== $name ==" >> audit_c.txt
  ~/workspace/laopu_ep1/asr_venv/bin/python asr_words.py ${name}.wav 2>/dev/null | tail -4 >> audit_c.txt
}
run s13a "$PWD/delivery.png,$W,$D"
run s13b "$PWD/delivery.png,$W,$D,$PWD/s13a_last.png"
run s14 "$PWD/delivery.png,$W,$D,$PWD/s13b_last.png"
run s15a "$PWD/tower.png,$W,$D"
run s15b "$PWD/tower.png,$W"
run s16 "$PWD/tower.png,$W,$D"
run s17 "$PWD/stove.png,$W,$D"
run s18 "$PWD/stove.png,$W,$D,$PWD/s17_last.png"
run s19 "$PWD/stove.png,$W,$D,$PWD/s18_last.png"
run s20a "$PWD/tower.png,$W,$D"
run s20b "$PWD/tower.png,$W,$D,$PWD/s19_last.png"
echo ALLDONE >> audit_c.txt
