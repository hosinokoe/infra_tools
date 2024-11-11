apigw() {
  aws $1 apigateway get-method --rest-api-id $2 --resource-id $3 --http-method $4
}
ssmpf() {
  aws $1 ssm start-session \
    --target $2 \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters host=$3,portNumber=$4,localPortNumber=$5
}
pon() {
	i=192.168.100.97:7890;export http_proxy=http://$i;export https_proxy=http://$i;export all_proxy=socks5://$i
}
poff() {
	unset i;unset http_proxy;unset https_proxy;unset all_proxy;
}
tfpsync() {
	sh ~/project/infra_tools/shell/tfpsync.sh
}
awson() {
  # 检查参数
  if [ $# -eq 0 ]; then
    echo "Usage: $0 arg1 arg2 arg3 ..."
    exit 1
  fi

  for arg in "$@"; do
    aws $arg sso login
    ~/.local/bin/yawsso -p $arg
  done
}
acg=~/project/infra_gehconfig/aws/config
gitcs=~/project/infra_gehconfig/gitconfig/
winuserp=$(powershell.exe -Command 'echo $env:userprofile')
winuser=$(echo $winuserp|cut -d '\' -f2)
winu=${winuser//$'\r'}
acgs() {
	ansible-vault decrypt $acg --vault-password-file=~/.ansible_secrets
	cp -p $acg ~/.aws/config
	cp -p $acg /mnt/c/Users/$winu/.aws/config 
	cd ~/project/infra_gehconfig;git checkout aws/config
}
gitsync() {
  ansible-vault decrypt $gitcs/.git-credentials --vault-password-file=~/.ansible_secrets
  cp -p $gitcs/{.git-credentials,.gitconfig} ~/
  mkdir -p ~/gitconfig;cp -p $gitcs/codecommit ~/gitconfig
  cd $gitcs;git checkout .git-credentials
}