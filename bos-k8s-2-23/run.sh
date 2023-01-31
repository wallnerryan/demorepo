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

########################
# Pre-reqs
# - csm-quickstart cluster 
#   with CSM auth installed
########################
# setup demo env
REPOS_BASE=${REPOS_BASE:-/home/ubuntu}
nodes_file="$REPOS_BASE/csm-quickstart/terraform/$TERRAFORM_DIR/nodes.txt"
public_ips_array=($(grep -A1 public  $node_file | tail -1))
IP1="${public_ips_array[0]}"

# install argocd
kubectl create namespace argocd
kubectl create -n argocd -f argocd-cm.yaml
kubectl create -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl patch svc argocd-server -n argocd -p '{"spec": { "type": "NodePort", "ports": [ { "name": "http", "nodePort": 30001, "port": 80 } ] } }'
kubectl patch svc argocd-server -n argocd -p '{"spec": { "type": "NodePort", "ports": [ { "name": "https", "nodePort": 30002, "port": 443 } ] } }'

# makesure to apply CRDs
kubectl create -f bos-k8s-2-23/CRDs/

# hide the evidence
clear

# Point ArgoCD at repo / dir
    # ArgoCD should be installed prior to demo
    # in the demo, get PW, login and configure new app
    # via the CLI or WebUI (comment out these lines for webui)
password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo)
argocd login $IP1:30002 --plaintext --username admin --password $password
p "ArgoCDUI: http://$IP1:30002/login"
pe "argocd cluster add default --in-cluster"
pe "argocd app create storage-auth-app -f bos-k8s-2-23/cluster1/auth-app.yaml "
pe "argocd app get storage-auth-app"
pe "argocd app sync storage-auth-app"

# sync auth resources (webui/cli?)
# These CLI commands run in the background and make the 
# sync action a reality of the "magic" CRDs/Objects beings shown
# *demo-magic* : background issue karavictl commands [ ]
karavictl role delete --insecure --addr role.csm-authorization.com:30737 \
  --role=Tenant1Role=powerflex=51719a66586a4b0f=pool1=100GB

karavictl role create --insecure --addr role.csm-authorization.com:30737 \
  --role=Tenant1Role=powerflex=51719a66586a4b0f=pool1=8GB

karavictl rolebinding create --tenant Tenant1 --role Tenant1Role --insecure \
  --addr tenant.csm-authorization.com:30737
    # Sync done via Argo WebUI (button click)
    # Sync done via CLi "$ argocd app sync external-storage-auth"

p "Show in Github and ArgoCD UI"

# create postgres, pvc will fail, show logs of pvc
pe "kubectl create ns pg"
pe "kubectl -n pg create -f bos-k8s-2-23/cluster1/app/postgres-pflex.yaml"
pe "kubectl -n pg get po,pvc"
pe "kubectl -n pg describe pvc"
# view auth resource of Role, shows only 8gb
    # view in ArgoCD UI 
    # or
    # kubectl get storagerole
    # kubectl describe storagerole my-storage-role

# update auth role resource role to 100GB via git commit/push
    # do this as a PR from Github.com
    # argo sync [ HAPPENS AUTOMATICALLY ]

# *demo-magic* : background issue karavictl commands 
karavictl role delete --insecure --addr role.csm-authorization.com:30737 \
  --role=Tenant1Role=powerflex=51719a66586a4b0f=pool1=8GB

karavictl role create --insecure --addr role.csm-authorization.com:30737 \
--role=Tenant1Role=powerflex=51719a66586a4b0f=pool1=100GB

karavictl rolebinding create --tenant Tenant1 --role Tenant1Role --insecure \
  --addr tenant.csm-authorization.com:30737

p "Submit and Merge PR in Github and show ArgoCD UI"

# delete and re-create app [DONE]
pe "kubectl -n pg delete -f bos-k8s-2-23/cluster1/app/postgres-pflex.yaml"
pe "kubectl -n pg create -f bos-k8s-2-23/cluster1/app/postgres-pflex.yaml"
pe "kubectl -n pg get po,pvc"
# app should succeed [DONE]

# Put your stuff here
pe "echo 'hello world' > file.txt"

#cat the file
pe "cat file.txt"

# run commands behind the scenes to cleanup
argocd app delete storage-auth-app
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl delete -n argocd -f argocd-cm.yaml
kubectl delete namespace argocd

# show a prompt so as not to reveal our true nature after
# the demo has concluded
p ""
