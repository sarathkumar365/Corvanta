#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/docura-backend"
PYTHON_DIR="$ROOT_DIR/intelligence-service"
RUNTIME_DIR="$ROOT_DIR/.run"

RABBITMQ_USERNAME="${RABBITMQ_USERNAME:-default}"
RABBITMQ_PASSWORD="${RABBITMQ_PASSWORD:-default}"
RABBITMQ_HOST="${RABBITMQ_HOST:-localhost}"
RABBITMQ_PORT="${RABBITMQ_PORT:-5672}"
RABBITMQ_VHOST="${RABBITMQ_VHOST:-/}"

JAVA_PID_FILE="$RUNTIME_DIR/docura-backend.pid"
PYTHON_PID_FILE="$RUNTIME_DIR/intelligence-service.pid"
JAVA_LOG_FILE="$RUNTIME_DIR/docura-backend.log"
PYTHON_LOG_FILE="$RUNTIME_DIR/intelligence-service.log"
MANAGER_LOG_FILE="$RUNTIME_DIR/manager.log"

mkdir -p "$RUNTIME_DIR"

usage() {
  cat <<USAGE
Usage:
  scripts/dev-services.sh start
  scripts/dev-services.sh stop
  scripts/dev-services.sh health
USAGE
}

log_manager() {
  local message="$1"
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$message" >> "$MANAGER_LOG_FILE"
}

is_running() {
  local pid="$1"
  kill -0 "$pid" 2>/dev/null
}

read_pid() {
  local pid_file="$1"
  if [[ -f "$pid_file" ]]; then
    cat "$pid_file"
  fi
}

wait_for_stop() {
  local pid="$1"
  for _ in {1..20}; do
    if ! is_running "$pid"; then
      return 0
    fi
    sleep 0.5
  done
  return 1
}

kill_process() {
  local pid="$1"
  local label="$2"

  if ! is_running "$pid"; then
    return 0
  fi

  log_manager "Stopping $label pid=$pid with SIGTERM"
  kill "$pid" 2>/dev/null || true
  if wait_for_stop "$pid"; then
    return 0
  fi

  log_manager "Force stopping $label pid=$pid with SIGKILL"
  kill -9 "$pid" 2>/dev/null || true
  wait_for_stop "$pid" || true
}

java_listener_pid() {
  lsof -t -nP -iTCP:8080 -sTCP:LISTEN 2>/dev/null | head -n1 || true
}

python_worker_pids() {
  local pids=""
  pids="$(pgrep -f "$PYTHON_DIR/.venv/bin/python app/main.py" || true)"
  if [[ -z "$pids" ]]; then
    pids="$(pgrep -f "python.*app/main.py" || true)"
  fi
  echo "$pids"
}

cleanup_stale_pid_file() {
  local pid_file="$1"
  local label="$2"
  local pid="$(read_pid "$pid_file")"

  if [[ -z "$pid" ]]; then
    return 0
  fi

  if is_running "$pid"; then
    return 0
  fi

  log_manager "Removing stale PID file for $label pid=$pid"
  rm -f "$pid_file"
}

ensure_python_env() {
  if [[ ! -d "$PYTHON_DIR/.venv" ]]; then
    log_manager "Creating Python virtual environment"
    (cd "$PYTHON_DIR" && python3 -m venv .venv)
  fi

  if [[ ! -x "$PYTHON_DIR/.venv/bin/python" ]]; then
    echo "python: missing virtual environment interpreter at .venv/bin/python" >&2
    exit 1
  fi

  if ! "$PYTHON_DIR/.venv/bin/python" -c "import aio_pika, dotenv, pydantic" >/dev/null 2>&1; then
    log_manager "Installing Python dependencies"
    (cd "$PYTHON_DIR" && "$PYTHON_DIR/.venv/bin/pip" install -r requirements.txt)
  fi
}

start_java() {
  cleanup_stale_pid_file "$JAVA_PID_FILE" "java"

  local managed_pid="$(read_pid "$JAVA_PID_FILE")"
  if [[ -n "$managed_pid" ]] && is_running "$managed_pid"; then
    echo "java: already running (pid=$managed_pid)"
    return 0
  fi

  local listener_pid
  listener_pid="$(java_listener_pid)"
  if [[ -n "$listener_pid" ]]; then
    log_manager "Found existing java listener on 8080 pid=$listener_pid; cleaning up"
    kill_process "$listener_pid" "java-listener"
  fi

  rm -f "$JAVA_PID_FILE"
  : > "$JAVA_LOG_FILE"

  echo "java: starting docura-backend"
  (
    cd "$BACKEND_DIR"
    nohup env \
      SPRING_RABBITMQ_USERNAME="$RABBITMQ_USERNAME" \
      SPRING_RABBITMQ_PASSWORD="$RABBITMQ_PASSWORD" \
      SPRING_RABBITMQ_HOST="$RABBITMQ_HOST" \
      SPRING_RABBITMQ_PORT="$RABBITMQ_PORT" \
      SPRING_RABBITMQ_VIRTUAL_HOST="$RABBITMQ_VHOST" \
      ./mvnw spring-boot:run >> "$JAVA_LOG_FILE" 2>&1 &
    echo $! > "$JAVA_PID_FILE"
  )

  local pid="$(read_pid "$JAVA_PID_FILE")"
  if [[ -z "$pid" ]]; then
    echo "java: failed to start, check $JAVA_LOG_FILE" >&2
    exit 1
  fi

  for _ in {1..60}; do
    local listener_pid
    listener_pid="$(java_listener_pid)"
    if [[ -n "$listener_pid" ]]; then
      echo "$listener_pid" > "$JAVA_PID_FILE"
      pid="$listener_pid"
      echo "java: running (pid=$pid)"
      log_manager "Java healthy pid=$pid"
      return 0
    fi
    if rg -q "APPLICATION FAILED TO START|BUILD FAILURE|Error starting ApplicationContext" "$JAVA_LOG_FILE"; then
      echo "java: failed during startup, check $JAVA_LOG_FILE" >&2
      exit 1
    fi
    sleep 1
  done

  echo "java: health check timeout, check $JAVA_LOG_FILE" >&2
  exit 1
}

start_python() {
  cleanup_stale_pid_file "$PYTHON_PID_FILE" "python"
  ensure_python_env

  local managed_pid="$(read_pid "$PYTHON_PID_FILE")"
  if [[ -n "$managed_pid" ]] && is_running "$managed_pid"; then
    echo "python: already running (pid=$managed_pid)"
    return 0
  fi

  local existing_pids
  existing_pids="$(python_worker_pids)"
  if [[ -n "$existing_pids" ]]; then
    while IFS= read -r pid; do
      [[ -z "$pid" ]] && continue
      log_manager "Found existing python worker pid=$pid; cleaning up"
      kill_process "$pid" "python-worker"
    done <<< "$existing_pids"
  fi

  rm -f "$PYTHON_PID_FILE"
  : > "$PYTHON_LOG_FILE"

  echo "python: starting intelligence-service"
  (
    cd "$PYTHON_DIR"
    nohup env \
      RABBITMQ_USERNAME="$RABBITMQ_USERNAME" \
      RABBITMQ_PASSWORD="$RABBITMQ_PASSWORD" \
      RABBITMQ_HOST="$RABBITMQ_HOST" \
      RABBITMQ_PORT="$RABBITMQ_PORT" \
      RABBITMQ_VHOST="$RABBITMQ_VHOST" \
      "$PYTHON_DIR/.venv/bin/python" app/main.py >> "$PYTHON_LOG_FILE" 2>&1 &
    echo $! > "$PYTHON_PID_FILE"
  )

  local pid="$(read_pid "$PYTHON_PID_FILE")"
  if [[ -z "$pid" ]] || ! is_running "$pid"; then
    echo "python: failed to start, check $PYTHON_LOG_FILE" >&2
    exit 1
  fi

  for _ in {1..20}; do
    if ! is_running "$pid"; then
      echo "python: exited during startup, check $PYTHON_LOG_FILE" >&2
      exit 1
    fi
    sleep 1
  done

  echo "python: running (pid=$pid)"
  log_manager "Python healthy pid=$pid"
}

stop_java() {
  cleanup_stale_pid_file "$JAVA_PID_FILE" "java"

  local managed_pid="$(read_pid "$JAVA_PID_FILE")"
  if [[ -n "$managed_pid" ]]; then
    kill_process "$managed_pid" "java-managed"
  fi

  local listener_pid
  listener_pid="$(java_listener_pid)"
  if [[ -n "$listener_pid" ]]; then
    kill_process "$listener_pid" "java-listener"
  fi

  rm -f "$JAVA_PID_FILE"
  echo "java: stopped"
}

stop_python() {
  cleanup_stale_pid_file "$PYTHON_PID_FILE" "python"

  local managed_pid="$(read_pid "$PYTHON_PID_FILE")"
  if [[ -n "$managed_pid" ]]; then
    kill_process "$managed_pid" "python-managed"
  fi

  local pids
  pids="$(python_worker_pids)"
  if [[ -n "$pids" ]]; then
    while IFS= read -r pid; do
      [[ -z "$pid" ]] && continue
      kill_process "$pid" "python-worker"
    done <<< "$pids"
  fi

  rm -f "$PYTHON_PID_FILE"
  echo "python: stopped"
}

health_report() {
  cleanup_stale_pid_file "$JAVA_PID_FILE" "java"
  cleanup_stale_pid_file "$PYTHON_PID_FILE" "python"

  local java_state="DOWN"
  local python_state="DOWN"
  local java_pid="$(read_pid "$JAVA_PID_FILE")"
  local python_pid="$(read_pid "$PYTHON_PID_FILE")"

  if [[ -n "$(java_listener_pid)" ]]; then
    java_state="UP"
  fi

  if [[ -n "$python_pid" ]] && is_running "$python_pid"; then
    python_state="UP"
  else
    local detected_python
    detected_python="$(python_worker_pids)"
    if [[ -n "$detected_python" ]]; then
      python_state="UP"
      python_pid="$(echo "$detected_python" | head -n1)"
      echo "$python_pid" > "$PYTHON_PID_FILE"
    fi
  fi

  if [[ "$java_state" == "UP" ]]; then
    local detected_java
    detected_java="$(java_listener_pid)"
    if [[ -n "$detected_java" ]]; then
      java_pid="$detected_java"
      echo "$java_pid" > "$JAVA_PID_FILE"
    fi
  fi

  if [[ "$python_state" == "UP" ]]; then
    python_state="UP"
  fi

  echo "java: $java_state ${java_pid:+(pid=$java_pid)}"
  echo "python: $python_state ${python_pid:+(pid=$python_pid)}"
  echo "logs: java=$JAVA_LOG_FILE python=$PYTHON_LOG_FILE manager=$MANAGER_LOG_FILE"

  if [[ "$java_state" == "UP" && "$python_state" == "UP" ]]; then
    return 0
  fi
  return 1
}

action="${1:-}"

case "$action" in
  start)
    start_java
    start_python
    health_report || true
    ;;
  stop)
    stop_python
    stop_java
    health_report || true
    ;;
  health)
    health_report
    ;;
  *)
    usage
    exit 1
    ;;
esac
