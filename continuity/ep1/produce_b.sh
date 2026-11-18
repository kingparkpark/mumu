#!/bin/bash
cd ~/workspace/ep1_full
W=$HOME/workspace/ep1_remake/world_master.png
D=$HOME/workspace/user/media_library/image/upload-4.jpg
run() { name=$1; feeds=$2;
  python3 gen.py $name "$feeds" || { echo "GENFAIL $name" >> audit_b.txt; return; }
  ffmpeg -y -v error -sseof -0.1 -i ${name}_raw.mp4 -frames:v 1 ${name}_last.png
  ffmpeg -y -v error -i ${name}_raw.mp4 -vf "fps=2,scale=360:640,tile=5x4:padding=2:margin=2" -frames:v 1 ${name}_tiles.png
  ffmpeg -y -v error -i ${name}_raw.mp4 -vn -ar 16000 -ac 1 ${name}.wav
  echo "== $name ==" >> audit_b.txt
  ~/workspace/laopu_ep1/asr_venv/bin/python asr_words.py ${name}.wav 2>/dev/null | tail -4 >> audit_b.txt
}
run s02r "$W,$PWD/noodle.png,$PWD/stove.png,$D"
run s05ar "$W,$PWD/crane.png,$D"
run s05br "$W,$PWD/crane.png,$D,$PWD/s05ar_last.png"
run s06br "$PWD/tower.png,$W,$D"
run s07a "$PWD/tower.png,$W,$D"
run s07b "$PWD/tower.png,$PWD/scanner.png,$W,$D,$PWD/s07a_last.png"
run s08a "$W,$D"
run s08b "$W,$D,$PWD/s08a_last.png"
run s09a "$PWD/tower.png,$W,$D"
run s09b "$PWD/tower.png,$W,$D,$PWD/s09a_last.png"
run s10 "$PWD/tower.png,$W,$D"
run s11 "$PWD/tower.png,$W,$D"
run s12a "$PWD/tower.png,$W,$D"
run s12b "$PWD/tower.png,$W,$D,$PWD/s12a_last.png"
echo ALLDONE >> audit_b.txt
