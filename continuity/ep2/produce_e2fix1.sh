#!/bin/bash
cd ~/workspace/ep2_full
W=$PWD/wolf_ep2.png
R=$PWD/ruins.png
run() { name=$1; feeds=$2;
  python3 gen.py $name "$feeds" || { echo "GENFAIL $name" >> audit_e2fix.txt; return; }
  ffmpeg -y -v error -sseof -0.1 -i ${name}_raw.mp4 -frames:v 1 ${name}_last.png
  ffmpeg -y -v error -i ${name}_raw.mp4 -vf "fps=2,scale=360:640,tile=5x4:padding=2:margin=2" -frames:v 1 ${name}_tiles.png
  ffmpeg -y -v error -i ${name}_raw.mp4 -vn -ar 16000 -ac 1 ${name}.wav
  echo "== $name ==" >> audit_e2fix.txt
  ~/workspace/laopu_ep1/asr_venv/bin/python asr_words.py ${name}.wav 2>/dev/null | tail -4 >> audit_e2fix.txt
}
run s06a2 "$R,$W"
run s06b2 "$PWD/s06a2_last.png,$W,$R"
run s08b2 "$PWD/s08a_last.png,$W"
echo ALLDONE >> audit_e2fix.txt
