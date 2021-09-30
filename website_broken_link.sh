#!/usr/bin/env bash

RET_OK=0
RET_ERR=-1
RESULT=${RET_OK}
RED="\e[31m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"

function log() {
   echo -e "[#${BASH_LINENO[-2]}] $1"
}

function log_error() {
   log "${RED}ERROR:${ENDCOLOR} $1"
}

function log_warning() {
   log "${YELLOW}WARNING:${ENDCOLOR} $1"
}

# replace string
function replace() {
   local string=$1
   local substr=$2
   echo ${string/${substr}}
}

function get_L10N_CODE() {
   local lookup_path=$1
   local result=${RET_ERR}

   for l10n_code in "${L10N_CODES[@]}"; do
      if [[ ${lookup_path} == */${l10n_code}/* ]] || \
         [[ ${lookup_path} == ${l10n_code}/* ]]; then
         result=${l10n_code}
         break
      fi
   done

   echo ${result}
}


function test_file_exist() {
   local lookup_path=$1
   local result=${RET_ERR}
   local lookup

   local dir=$(dirname $lookup_path)
   local file=$(basename $lookup_path)
   lookup=${dir}/${file}.md

   if [ -f ${lookup} ]; then
      result=${RET_OK}
   else
      lookup=${dir}/${file}/_index.md
      if [ -f ${lookup} ]; then
         result=${RET_OK}
      fi
   fi

   echo ${result}
}

# 1. when L10N available, returns L10N link
# 2. if L10N is unavailable, returns ORIGINAL LINK
# 3. either two options are unavailable, returns error
function get_L10N_link() {
   local path=$1
   local full_path
   local result=${RET_ERR}

   has_code=$(get_L10N_CODE ${path})
   if [[ $has_code == ${RET_ERR} ]]; then
      full_path=${L10N_ROOT}/${CODE}/${path}
   elif [[ $has_code == ${CODE} ]]; then
      full_path=${L10N_ROOT}/${path}
   else
      # Other L10N CODE link might be used.
      echo ${result}
      return
   fi

   # 1. Test L10N full_path exists. Returns L10N path
   if [[ $(test_file_exist ${full_path}) == ${RET_OK} ]]; then
      result=$(replace ${full_path} ${L10N_ROOT}/)
      echo ${result}
      return
   fi
   # 2. Fall-back to ORIGINAL full_path exists. Returns ORIGINAL path
   full_path=${L10N_ROOT}/en/${path}
   if [[ $(test_file_exist ${full_path}) == ${RET_OK} ]]; then
      result=$(replace ${full_path} ${L10N_ROOT}/en/)
      echo ${result}
      return
   fi
   # 3. Returns error
   echo ${result}
}

SCRIPT_DIR=$(dirname $0)
ROOT=$(replace ${SCRIPT_DIR} '/scripts')
FILE=$1

[[ -z ${FILE} ]] \
   && echo "Specify file to check." \
   && echo "ex) ./scripts/run.sh content/ko/docs/concepts/extend-kubernetes/api-extension/custom-resources.md" \
   && exit ${RET_ERR}

FILE=$(replace ${FILE} './')
FILE_PATH=${ROOT}/${FILE}

[[ ! -f ${FILE_PATH} ]] \
   && echo "File ${FILE_PATH} not exists." \
   && exit ${RET_ERR}

L10N_ROOT=${ROOT}/content
L10N_CODES=($(ls ${L10N_ROOT}))
CODE=$(get_L10N_CODE ${FILE_PATH})

# EXCLUDE_LIST=( 'generated/' 'images' '.png' '.svg')
# Move to EXCLUDE_LIST_ARRAY
# Fetch string between '(/' and ')'. Exclude 'generated/'
LINKS=$(grep -o -P '(?<=\(/).*?(?=\))' ${FILE_PATH} \
   | grep docs \
   | egrep -v 'images|generated/|.png|.svg' \
   | sed 's| |%%|g')

for link in ${LINKS[@]}; do
   # remove ID anchor
   link=$(replace ${link} '\#*')
   l10n_link=$(get_L10N_link ${link})

   [[ ${link} == *%%* ]] \
      && log_error "Link malformed! whitespace!" \
      && log ${link}

   if [[ ${l10n_link} == ${RET_ERR} ]]; then
      log_error "Wrong link! Maybe link outdated?"
      RESULT=${RET_ERR}
      log ${link}
   elif [[ ${l10n_link} != ${link} ]]; then
      log_warning "Alternative link exists!"
      RESULT=${RET_ERR}
      log ${link}
      log ${l10n_link}
   fi
done

exit ${RESULT}