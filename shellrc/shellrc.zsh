#*****************CURR_FILE_DIR*****************
# Get directory of current script file, follow symlink if needed.
CURR_FILE="${(%):-%N}"
if [ -L ${CURR_FILE} ]; then
	CURR_FILE=`readlink ${CURR_FILE}`
fi
CURR_FILE_DIR="$(cd "$(dirname "${CURR_FILE}" )" && pwd )"
#*****************CURR_FILE_DIR*****************

source ${CURR_FILE_DIR}/shellrc.generic
source ${CURR_FILE_DIR}/github.generic

if exist tmuxinator; then
	source ${CURR_FILE_DIR}/tmuxinator.zsh
fi

unset CURR_FILE_DIR
