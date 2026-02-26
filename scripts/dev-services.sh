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

mkdir -p "$RUNTIME_DIR"

usage() {
  cat <<USAGE
Usage:
  scripts/dev-services.sh start [all|java|python]
  scripts/dev-services.sh stop [all|java|python]
  scripts/dev-services.sh restart [all|java|python]
  scripts/dev-services.sh status [all|java|python]
  scripts/dev-services.sh logs [all|java|python] [--follow]

Examples:
  scripts/dev-services.sh start all
  scripts/dev-services.sh restart java
  scripts/dev-services.sh stop python
  scripts/dev-services.sh logs all
  scripts/dev-services.sh logs java --follow
USAGE
}

is_running() {
  local pid="$1"
  kill -0 "$pid" 2>/dev/null
}

read_pid() {
  local pid_file="$1"
  if [[ -f "$pid_file" ]]; then
    cat "$pid_file"
  else
    echo ""
  fi
}

service_files() {
  local service="$1"
  case "$service" in
    java)
      echo "$JAVA_PID_FILE|$JAVA_LOG_FILE|$BACKEND_DIR"
      ;;
    python)
      echo "$PYTHON_PID_FILE|$PYTHON_LOG_FILE|$PYTHON_DIR"
      ;;
    *)
      echo "Unknown service: $service" >&2
      exit 1
      ;;
  esac
}

print_logs() {
  local service="$1"
  local follow="${2:-false}"
  IFS='|' read -r _ log_file _ <<< "$(service_files "$service")"

  if [[ ! -f "$log_file" ]]; then
    echo "$service: log file not found at $log_file"
    return
  fi

  echo "===== $service log: $log_file ====="
  if [[ "$follow" == "true" ]]; then
    tail -n 80 -f "$log_file"
  else
    tail -n 80 "$log_file"
  fi
}

print_status() {
  local service="$1"
  IFS='|' read -r pid_file log_file _ <<< "$(service_files "$service")"
  local pid
  pid="$(read_pid "$pid_file")"

  if [[ -n "$pid" ]] && is_running "$pid"; then
    echo "$service: running (pid=$pid, log=$log_file)"
  else
    echo "$service: stopped"
  fi
}

ensure_python_env() {
  if [[ ! -d "$PYTHON_DIR/.venv" ]]; then
    echo "python: creating virtual environment at $PYTHON_DIR/.venv"
    (cd "$PYTHON_DIR" && python3 -m venv .venv)
  fi

  if [[ ! -x "$PYTHON_DIR/.venv/bin/python" ]]; then
    echo "python: missing virtual environment interpreter at .venv/bin/python" >&2
    exit 1
  fi

  if ! "$PYTHON_DIR/.venv/bin/python" -c "import aio_pika, dotenv, pydantic" >/dev/null 2>&1; then
    echo "python: installing dependencies from requirements.txt"
    (cd "$PYTHON_DIR" && "$PYTHON_DIR/.venv/bin/pip" install -r requirements.txt)
  fi
}

start_service() {
  local service="$1"
  IFS='|' read -r pid_file log_file service_dir <<< "$(service_files "$service")"
  local pid
  pid="$(read_pid "$pid_file")"

  if [[ -n "$pid" ]] && is_running "$pid"; then
    echo "$service: already running (pid=$pid)"
    return
  fi

  rm -f "$pid_file"
  : > "$log_file"

  case "$service" in
    java)
      echo "java: starting docura-backend"
      (
        cd "$service_dir"
        nohup env \
          SPRING_RABBITMQ_USERNAME="$RABBITMQ_USERNAME" \
          SPRING_RABBITMQ_PASSWORD="$RABBITMQ_PASSWORD" \
          SPRING_RABBITMQ_HOST="$RABBITMQ_HOST" \
          SPRING_RABBITMQ_PORT="$RABBITMQ_PORT" \
          SPRING_RABBITMQ_VIRTUAL_HOST="$RABBITMQ_VHOST" \
          ./mvnw spring-boot:run >> "$log_file" 2>&1 &
        echo $! > "$pid_file"
      )
      ;;
    python)
      ensure_python_env
      echo "python: starting intelligence-service"
      (
        cd "$service_dir"
        nohup env \
          RABBITMQ_USERNAME="$RABBITMQ_USERNAME" \
          RABBITMQ_PASSWORD="$RABBITMQ_PASSWORD" \
          RABBITMQ_HOST="$RABBITMQ_HOST" \
          RABBITMQ_PORT="$RABBITMQ_PORT" \
          RABBITMQ_VHOST="$RABBITMQ_VHOST" \
          "$PYTHON_DIR/.venv/bin/python" app/main.py >> "$log_file" 2>&1 &
        echo $! > "$pid_file"
      )
      ;;
  esac

  sleep 1
  pid="$(read_pid "$pid_file")"
  if [[ -n "$pid" ]] && is_running "$pid"; then
    echo "$service: started (pid=$pid, log=$log_file)"
  else
    echo "$service: failed to start, check log=$log_file" >&2
    exit 1
  fi
}

stop_service() {
  local service="$1"
  IFS='|' read -r pid_file _ _ <<< "$(service_files "$service")"
  local pid
  pid="$(read_pid "$pid_file")"

  if [[ -z "$pid" ]] || ! is_running "$pid"; then
    rm -f "$pid_file"
    echo "$service: already stopped"
    return
  fi

  echo "$service: stopping (pid=$pid)"
  kill "$pid" 2>/dev/null || true

  for _ in {1..20}; do
    if ! is_running "$pid"; then
      rm -f "$pid_file"
      echo "$service: stopped"
      return
    fi
    sleep 0.5
  done

  echo "$service: forcing stop (pid=$pid)"
  kill -9 "$pid" 2>/dev/null || true
  rm -f "$pid_file"
}

run_action() {
  local action="$1"
  local target="$2"
  local follow="${3:-false}"

  case "$target" in
    all)
      if [[ "$action" == "start" ]]; then
        start_service java
        start_service python
      elif [[ "$action" == "stop" ]]; then
        stop_service python
        stop_service java
      elif [[ "$action" == "restart" ]]; then
        stop_service python
        stop_service java
        start_service java
        start_service python
      elif [[ "$action" == "status" ]]; then
        print_status java
        print_status python
      elif [[ "$action" == "logs" ]]; then
        print_logs java "$follow"
        print_logs python "$follow"
      fi
      ;;
    java|python)
      if [[ "$action" == "start" ]]; then
        start_service "$target"
      elif [[ "$action" == "stop" ]]; then
        stop_service "$target"
      elif [[ "$action" == "restart" ]]; then
        stop_service "$target"
        start_service "$target"
      elif [[ "$action" == "status" ]]; then
        print_status "$target"
      elif [[ "$action" == "logs" ]]; then
        print_logs "$target" "$follow"
      fi
      ;;
    *)
      echo "Invalid target: $target" >&2
      usage
      exit 1
      ;;
  esac
}

action="${1:-}"
target="${2:-all}"
follow_flag="${3:-}"
follow_mode="false"

if [[ "$follow_flag" == "--follow" ]]; then
  follow_mode="true"
elif [[ -n "$follow_flag" ]]; then
  echo "Invalid flag: $follow_flag" >&2
  usage
  exit 1
fi

case "$action" in
  start|stop|restart|status|logs)
    run_action "$action" "$target" "$follow_mode"
    ;;
  *)
    usage
    exit 1
    ;;
esac
