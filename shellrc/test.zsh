# Get directory of current script file, follow symlink if needed.
CURR_FILE="${(%):-%N}"
if [ -L ${CURR_FILE} ]; then
	CURR_FILE=`readlink ${CURR_FILE}`
fi
CURR_FILE_DIR="$(cd "$(dirname "${CURR_FILE}" )" && pwd )"

echo ${CURR_FILE}
echo ${CURR_FILE_DIR}
