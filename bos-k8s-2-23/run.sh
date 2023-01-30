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
# makesure to apply CRDs [ ]
# create a repo for the "auth gitops" [DONE]
    # https://github.com/wallnerryan/demorepo/tree/main/bos-k8s-2-23/cluster1
# put real json / yaml objects in the repo [DONE]
# install ArgoCD, point at repo dir [ ]
# sync auth resources (webui/cli?) [ ]
# *demo-magic* : background issue karavictl commands [ ]
# create postgres, pvc will fail, show logs of pvc [ ]
# view auth resource of Role, shows only 8gb [ ]
    # kubectl get storagerole
    # kubectl describe storagerole my-storage-role
# update auth role resource role to 100GB via git commit/push [ ]
# argo sync [ ]
# *demo-magic* : background issue karavictl commands [ ]
# delete and re-create app [ ]
# app should succeed [ ]

# Put your stuff here
pe "echo 'hello world' > file.txt"

#cat the file
pe "cat file.txt"

# run command behind the scenes
rm -rf file.txt

# show a prompt so as not to reveal our true nature after
# the demo has concluded
p ""
