#!/bin/bash
cd ~/workspace/ep1_full
W=$HOME/workspace/ep1_remake/world_master.png
D=$HOME/workspace/user/media_library/image/upload-4.jpg
run() { name=$1; feeds=$2;
  python3 gen.py $name "$feeds" || { echo "GENFAIL $name" >> audit.txt; return; }
  ffmpeg -y -v error -sseof -0.1 -i ${name}_raw.mp4 -frames:v 1 ${name}_last.png
  ffmpeg -y -v error -i ${name}_raw.mp4 -vf "fps=2,scale=360:640,tile=5x4:padding=2:margin=2" -frames:v 1 ${name}_tiles.png
  ffmpeg -y -v error -i ${name}_raw.mp4 -vn -ar 16000 -ac 1 ${name}.wav
  echo "== $name ==" >> audit.txt
  ~/workspace/laopu_ep1/asr_venv/bin/python asr_words.py ${name}.wav 2>/dev/null | tail -4 >> audit.txt
}
run s02 "$PWD/noodle.png,$PWD/stove.png,$W,$D"
run s03 "$PWD/scanner.png,$W,$D"
run s04a "$PWD/drill.png,$W,$D"
run s04b "$PWD/drill.png,$W,$D,$PWD/s04a_last.png"
run s05a "$PWD/crane.png,$W,$D"
run s05b "$PWD/crane.png,$W,$D,$PWD/s05a_last.png"
run s06a "$PWD/tower.png,$W,$D"
run s06b "$PWD/tower.png,$W,$D,$PWD/s06a_last.png"
echo ALLDONE >> audit.txt
