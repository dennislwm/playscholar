function get_output {
  if [ -z "$1" ]; then
    echo "[Usage][$FUNCNAME]: $FUNCNAME URL"
    return 1
  fi
  FILE="${2}"
  if [ -z "${FILE}" ]; then
    FILE=output
  fi
  curl --version > /dev/null 2>&1 || ( echo "[ERROR][$FUNCNAME]: curl not installed." && return 1 )
  local url="https://r.jina.ai/$1"
  curl "${url}" -o "${FILE}.txt"
}