#!/bin/bash
cd ~/workspace/ep2_full
W=$PWD/wolf_ep2.png
R=$PWD/ruins.png
Z=$PWD/zombie_rider.png
run() { name=$1; feeds=$2;
  python3 gen.py $name "$feeds" || { echo "GENFAIL $name" >> audit_e2d.txt; return; }
  ffmpeg -y -v error -sseof -0.1 -i ${name}_raw.mp4 -frames:v 1 ${name}_last.png
  ffmpeg -y -v error -i ${name}_raw.mp4 -vf "fps=2,scale=360:640,tile=5x4:padding=2:margin=2" -frames:v 1 ${name}_tiles.png
  ffmpeg -y -v error -i ${name}_raw.mp4 -vn -ar 16000 -ac 1 ${name}.wav
  echo "== $name ==" >> audit_e2d.txt
  ~/workspace/laopu_ep1/asr_venv/bin/python asr_words.py ${name}.wav 2>/dev/null | tail -4 >> audit_e2d.txt
}
run s12a "$PWD/s12t2_last.png,$W"
run s13a "$Z,$W,$R"
run s13b "$PWD/s13a_last.png,$Z,$W,$R"
run s14 "$R"
run s15 "$W,$R"
echo ALLDONE >> audit_e2d.txt
