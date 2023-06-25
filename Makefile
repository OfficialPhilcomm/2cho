update:
	sudo systemctl stop 2cho
	git pull --rebase
	bundle i
	sudo systemctl start 2cho

restart:
	sudo service 2cho restart
