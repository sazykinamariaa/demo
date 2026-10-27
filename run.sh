#!/usr/bin/env bash
# Запуск «Клинического компаса» локально:  ./run.sh          (демо-данные включены)
#                                           KK_DEMO_SEED=0 ./run.sh   (чистая база)
set -e
cd "$(dirname "$0")"

pick_python() {
  for p in python3.13 python3.12 python3.11 python3.10 /opt/homebrew/bin/python3 /usr/local/bin/python3 python3; do
    if command -v "$p" >/dev/null 2>&1 && "$p" -c 'import sys; sys.exit(0 if sys.version_info >= (3,10) else 1)' 2>/dev/null; then
      command -v "$p"; return 0
    fi
  done
  return 1
}

if [ ! -x .venv/bin/python ] || ! .venv/bin/python -c 'import sys; sys.exit(0 if sys.version_info >= (3,10) else 1)' 2>/dev/null; then
  rm -rf .venv
  if PY="$(pick_python)"; then
    echo "Использую Python: $PY"
    "$PY" -m venv .venv
  else
    echo "На этом компьютере Python старше 3.10 (обычно 3.9 от Apple). Ставлю uv и нужный Python (один раз, ~1 минута)…"
    export PATH="$HOME/.local/bin:$PATH"
    command -v uv >/dev/null 2>&1 || curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
    uv venv --python 3.12 .venv
  fi
  if .venv/bin/python -m pip --version >/dev/null 2>&1; then
    .venv/bin/python -m pip install -q --upgrade pip
    .venv/bin/python -m pip install -q -r backend/requirements.txt
  else
    uv pip install -q --python .venv/bin/python -r backend/requirements.txt
  fi
fi

export KK_DEMO_SEED="${KK_DEMO_SEED:-1}"
export KK_DATA_DIR="${KK_DATA_DIR:-$PWD/data}"
cd backend
echo "Открывайте: http://127.0.0.1:8000/  (приложение);  /docs — документация API"
echo "Демо-вход: doctor1 / demo12345,  admin / demo12345,  psychiatrist / demo12345,  duty / demo12345,  patient_s5 / demo12345"
exec ../.venv/bin/python -m uvicorn app.main:app --host "${KK_HOST:-127.0.0.1}" --port 8000
