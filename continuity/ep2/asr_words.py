import sys, wave, numpy as np
from faster_whisper import WhisperModel
path = sys.argv[1]
w = wave.open(path, 'rb')
assert w.getframerate() == 16000 and w.getnchannels() == 1
frames = w.readframes(w.getnframes())
audio = np.frombuffer(frames, dtype=np.int16).astype(np.float32) / 32768.0
m = WhisperModel('small', device='cpu', compute_type='int8')
segs, _ = m.transcribe(audio, language='zh', word_timestamps=True, beam_size=5)
for s in segs:
    print(f'[{s.start:.1f}-{s.end:.1f}] {s.text}')
