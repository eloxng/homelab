# WireGuard
1) Download folder with all files
2) Add in details in the .env file for the following: FORWARDED_PORT, PUBLIC_IP, and LAN_ALLOWED_IP
3) Open the folder in terminal with root privileges "sudo su"
4) Run the install script "bash install.sh". This will install wireguard, iptables, and qrencode and setup wireguard for use.
5) Create connection .conf file "bash create_client_config.sh" and provide the file name for the .conf file.
