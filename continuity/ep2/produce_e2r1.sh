#!/bin/bash
cd ~/workspace/ep2_full
W=$PWD/wolf_ep2.png
R=$PWD/ruins.png
L=$PWD/lab_night.png
run() { name=$1; feeds=$2;
  python3 gen.py $name "$feeds" || { echo "GENFAIL $name" >> audit_e2r1.txt; return; }
  ffmpeg -y -v error -sseof -0.1 -i ${name}_raw.mp4 -frames:v 1 ${name}_last.png
  ffmpeg -y -v error -i ${name}_raw.mp4 -vf "fps=2,scale=360:640,tile=5x4:padding=2:margin=2" -frames:v 1 ${name}_tiles.png
  ffmpeg -y -v error -i ${name}_raw.mp4 -vn -ar 16000 -ac 1 ${name}.wav
  echo "== $name ==" >> audit_e2r1.txt
  ~/workspace/laopu_ep1/asr_venv/bin/python asr_words.py ${name}.wav 2>/dev/null | tail -4 >> audit_e2r1.txt
}
run s02b "$R,$W"
run s03c "$R,$W"
run s04a3 "$PWD/s03c_last.png,$W,$R"
run s06a4 "$L,$W,$R"
run s07b "$PWD/s04a3_last.png,$R"
run s09b "$PWD/s07b_last.png,$R"
echo ALLDONE >> audit_e2r1.txt
