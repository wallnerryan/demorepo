#!/bin/bash

########################
# include the magic
########################
. ../tools/demo-magic.sh

########################
# Configure the options
########################

#
# speed at which to simulate typing. bigger num = faster
#
# TYPE_SPEED=20

#
# custom prompt
#
# see http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html for escape sequences
#
DEMO_PROMPT="${GREEN} ${CYAN}\W ${COLOR_RESET}: "

# text color
# DEMO_CMD_COLOR=$BLACK

# hide the evidence
clear

#TODO
# create a repo for the "auth gitops"
# put real json / yaml objects in the repo
# update repos and in background fake that it actuall makes environment update with demo magic
# do a few examples with p and pe.

# Put your stuff here
pe "echo 'hello world' > file.txt"

#cat the file
pe "cat file.txt"

# run command behind the scenes
rm -rf file.txt

# show a prompt so as not to reveal our true nature after
# the demo has concluded
p ""
