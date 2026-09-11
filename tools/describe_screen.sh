#!/usr/bin/env bash
# Route an adb screenshot through the local vision model (LM Studio, must be
# running on localhost:1234) instead of reading the raw PNG into Claude's own
# context. Prints ONLY the model's text answer — no JSON wrapper.
#
# This is a first-pass triage tool, not a replacement for a real look: it
# reliably extracts verbatim error/snackbar text and gross layout breakage,
# but can miss secondary details and its suggested tap coordinates are
# unreliable guesses. If it flags something, or the screen matters for a
# decision, read the actual PNG before acting on it.
#
# Usage: tools/describe_screen.sh <path-to-png> ["extra instructions"]
set -euo pipefail

IMG="$1"
EXTRA="${2:-}"

if [ ! -f "$IMG" ]; then
  echo "ERROR: file not found: $IMG" >&2
  exit 1
fi

PROMPT="You are QA-ing a Flutter mobile app screenshot from an Android device. Describe ONLY what is useful for a bug sweep: (1) what screen/state this is, (2) exact visible text of any error/snackbar/dialog messages verbatim, (3) any obviously broken layout (overlap, clipping, missing content, misaligned/garbled text, empty-looking widgets, wrong pluralization/grammar). Be terse — bullet points, no preamble, no restating the question. If nothing looks wrong, say exactly: No visible issues. ${EXTRA}"

# Pass the image path and prompt via a temp env-free Python step (avoids
# Windows' command-line length limit that argv-passing the base64 blob hits).
IMG="$IMG" PROMPT="$PROMPT" python -c "
import base64, json, os, sys, urllib.request

img_path = os.environ['IMG']
prompt = os.environ['PROMPT']

with open(img_path, 'rb') as f:
    b64 = base64.b64encode(f.read()).decode('ascii')

body = json.dumps({
    'model': 'qwen2.5-vl-7b-instruct',
    'messages': [{
        'role': 'user',
        'content': [
            {'type': 'text', 'text': prompt},
            {'type': 'image_url', 'image_url': {'url': 'data:image/png;base64,' + b64}}
        ]
    }],
    'max_tokens': 500,
    'temperature': 0.1
}).encode('utf-8')

req = urllib.request.Request(
    'http://localhost:1234/v1/chat/completions',
    data=body,
    headers={'Content-Type': 'application/json'},
    method='POST',
)
with urllib.request.urlopen(req, timeout=60) as resp:
    result = json.load(resp)

print(result['choices'][0]['message']['content'])
"
