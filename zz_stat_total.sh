#!/bin/bash
# | de | en  es  fr  hi  id  it  ja  ko  no  pl  pt-br  ru  uk  vi  zh

CODES=(de  es  fr  hi  id  it  ja  ko  no  pl  pt-br  ru  uk  vi  zh)
ERR_CODES=()
TOTAL_DOCS=()

for CODE in ${CODES[@]}; do
  echo "==============================="
  echo "Checking $CODE translation docs"
  echo "==============================="
  TOTAL_CNT=0
  ERR_CNT=0

  DOCS=$(find content/$CODE/docs | grep \.md)
  for DOC in ${DOCS[@]}; do
    TOTAL_CNT=$(( $TOTAL_CNT + 1 ))
    ./scripts/website_broken_link.sh $DOC
    RST=$?
    if [ $RST -ne 0 ]; then
      ERR_CNT=$(( $ERR_CNT + 1 ))
    fi
  done
  
  TOTAL_DOCS+=($TOTAL_CNT)
  ERR_CODES+=($ERR_CNT)
done

function PRINT() {
  local TYPE=("$@")
  for T in ${TYPE[@]}; do
    printf "%5s" "$T" 
    printf " |"
  done
  printf "\n"
}


printf "==================================================================================================================\n"
tput bold; tput setaf 4  # Blue
printf "| CODE  |"
PRINT ${CODES[@]}
tput sgr0     # Normal
printf "==================================================================================================================\n"
tput bold; tput setaf 1  # Red
printf "| ERROR |"
PRINT ${ERR_CODES[@]}
tput sgr0     # Normal
printf "==================================================================================================================\n"
tput bold; tput setaf 3  # Yellow
printf "| TOTAL |"
tput sgr0     # Normal
PRINT ${TOTAL_DOCS[@]}
printf "==================================================================================================================\n"
