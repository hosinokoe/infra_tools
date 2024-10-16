zsc = shell/.zsh*
zdt = ~/

# copy .zshrc
zshrc:
	cp -rp $(zsc) $(zdt)

g3bk:
	ansible-vault decrypt shell/poweruser-roles.yaml --vault-password-file=~/.ansible_secrets
	cp shell/poweruser-roles.yaml ~
	git checkout shell/poweruser-roles.yaml
tfpsync:
	sh shell/tfpsync.sh
