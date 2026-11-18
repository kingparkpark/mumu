import json, os, subprocess, sys, glob, shutil, time
tag = sys.argv[1]; feeds = [f for f in sys.argv[2].split(',') if f]
prompt = open(f'{tag}.txt', encoding='utf-8').read()
conv = [{'image': f} for f in feeds] + [{'text': prompt}]
env = dict(os.environ); env.pop('JARVIS_TRACE_CONTEXT', None)
before = set(glob.glob(os.path.expanduser('~/workspace/imagine_media/*')))
r = subprocess.run(['/opt/hatch/bin/media-generation', '--media-subagent-output-type', 'video', '--conversation-json', json.dumps(conv, ensure_ascii=False)], capture_output=True, text=True, env=env)
print('exit', r.returncode); print((r.stdout or '')[-400:]); print((r.stderr or '')[-200:])
after = set(glob.glob(os.path.expanduser('~/workspace/imagine_media/*')))
new = sorted(after - before, key=os.path.getmtime)
if not new: print('NO OUTPUT'); sys.exit(1)
out = new[-1]
# Validate before copying: a real video is a large MP4 (ftyp box), not a
# JSON error document. On 2026-11-18 the region block returned 958-byte
# JSON error files which the old script copied as *_raw.mp4 and reported
# SAVED, hiding a 6/6 failure. Reject anything small or non-MP4 here.
size = os.path.getsize(out)
with open(out, 'rb') as fh:
    head = fh.read(16)
if size < 100000 or b'ftyp' not in head:
    print('GENFAIL', tag, 'output', out, 'size', size, 'head', head[:16])
    sys.exit(1)
shutil.copy(out, f'{tag}_raw.mp4'); print('SAVED', tag)
