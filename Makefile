update:
	sudo systemctl stop 2cho
	git pull --rebase
	sudo systemctl start 2cho
