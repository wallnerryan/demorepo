#!/bin/bash

########################
# Pre-reqs
# - csm-quickstart cluster 
#   with CSM auth installed
########################
# setup demo env
REPOS_BASE=${REPOS_BASE:-/home/ubuntu}
SSHKEY=${SSHKEY-~/.ssh/id_rsa}
TERRAFORM_DIR="aws-rhel-nodes-vpc"
PFLEX_U="admin"
PFLEX_P=${PFLEX_P-Password123}
VMUSER="ec2-user"

# setup kubeconfig
unset KUBECONFIG
export KUBECONFIG=$REPOS_BASE/csm-quickstart/terraform/$TERRAFORM_DIR/kube_config_rke-3-hosts.yml

# nodes, ports and ips
nodes_file="$REPOS_BASE/csm-quickstart/terraform/$TERRAFORM_DIR/nodes.txt"
public_ips_array=($(grep -A1 public  $nodes_file | tail -1))
IP1="${public_ips_array[0]}"
AUTH_NODE_PORT=$(kubectl get --namespace authorization -o jsonpath="{.spec.ports[1].nodePort}" service authorization-ingress-nginx-controller)

# install argocd
kubectl create namespace argocd
kubectl create -n argocd -f argocd-cm.yaml
kubectl create -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl patch svc argocd-server -n argocd -p '{"spec": { "type": "NodePort", "ports": [ { "name": "http", "nodePort": 30001, "port": 80 } ] } }'
kubectl patch svc argocd-server -n argocd -p '{"spec": { "type": "NodePort", "ports": [ { "name": "https", "nodePort": 30002, "port": 443 } ] } }'
until kubectl -n argocd get secret argocd-initial-admin-secret
do
  echo "Waiting for ArgoCD"
done

password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo)
until argocd login $IP1:30002 --plaintext --username admin --password $password
do
  echo "Waiting to Login to ArgoCD"
done

# makesure to apply CRDs
kubectl create -f CRDs/

# get pflex info
ssh -i $SSHKEY $VMUSER@$IP1 scli --login --username $PFLEX_U --password $PFLEX_P --approve_certificate
systemid=$(ssh -i $SSHKEY $VMUSER@$IP1 scli --query_properties --object_type SYSTEM --all_objects  --properties ID)
pflexsystemid=$(echo $systemid | awk '{print $4}')

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

# Point ArgoCD at repo / dir
    # ArgoCD should be installed prior to demo
    # in the demo, get PW, login and configure new app
    # via the CLI or WebUI (comment out these lines for webui)
echo "ArgoCD UI: http://$IP1:30002/login password: $password" 
pe " argocd cluster add local --in-cluster -y"
pe "argocd app create storage-auth-app -f cluster1/auth-app.yaml "
pe "argocd app get storage-auth-app"
# pe "argocd app sync storage-auth-app" #(not needed, app syncs automatically)

# sync auth resources (webui/cli?)
# These CLI commands run in the background and make the 
# sync action a reality of the "magic" CRDs/Objects beings shown
# *demo-magic* : background issue karavictl commands [ ]
karavictl role delete --insecure --addr role.csm-authorization.com:$AUTH_NODE_PORT \
  --role=Tenant1Role=powerflex=$pflexsystemid=pool1=100GB

karavictl role create --insecure --addr role.csm-authorization.com:$AUTH_NODE_PORT \
  --role=Tenant1Role=powerflex=$pflexsystemid=pool1=8GB

karavictl rolebinding create --tenant Tenant1 --role Tenant1Role --insecure \
  --addr tenant.csm-authorization.com:$AUTH_NODE_PORT
    # Sync done via Argo WebUI (button click)
    # Sync done via CLi "$ argocd app sync external-storage-auth"

echo "Let's create an app"

# create postgres, pvc will fail, show logs of pvc
pe "kubectl create ns pg"
pe "kubectl -n pg create -f cluster1/app/postgres-pflex.yaml"
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
karavictl role delete --insecure --addr role.csm-authorization.com:$AUTH_NODE_PORT \
  --role=Tenant1Role=powerflex=$pflexsystemid=pool1=8GB

karavictl role create --insecure --addr role.csm-authorization.com:$AUTH_NODE_PORT \
--role=Tenant1Role=powerflex=$pflexsystemid=pool1=100GB

karavictl rolebinding create --tenant Tenant1 --role Tenant1Role --insecure \
  --addr tenant.csm-authorization.com:$AUTH_NODE_PORT

echo "Submit and Merge PR to increase quota in Github"

# delete and re-create app [DONE]
pe "kubectl -n pg delete -f cluster1/app/postgres-pflex.yaml"
pe "kubectl -n pg create -f cluster1/app/postgres-pflex.yaml"
pe "kubectl -n pg get po,pvc"
# app should succeed [DONE]

p ""

# run commands behind the scenes to cleanup
echo "....cleanup"
kubectl -n pg delete -f cluster1/app/postgres-pflex.yaml
kubectl delete ns pg
argocd cluster rm local -y
argocd app delete storage-auth-app -y
kubectl delete -n argocd -f argocd-cm.yaml
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl delete namespace argocd
kubectl delete -f CRDs/

# show a prompt so as not to reveal our true nature after
# the demo has concluded
p ""
