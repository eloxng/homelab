# Load variables from .env file
source "$(dirname "$0")/.env" 

# Load functions from functions.sh to use here
source ./functions.sh	      

echo "*** (1) Update system packages ***"

# Find any updates required
sudo apt update && sudo apt upgrade -y

install_app "wireguard"
install_app "iptables"
install_app "qrencode"

echo "*** (2) Generating keys for /etc/wireguard/wg0.conf ***"

# SERVER_PRIVATE_KEY: Path where server private key file will exist
# SERVER_PUBLIC_KEY: Path where server public key file will exist
SERVER_PRIVATE_KEY="$SERVER_KEY_PATH$SERVER_PRIVATE_KEY_FILE_NAME"
SERVER_PUBLIC_KEY="$SERVER_KEY_PATH$SERVER_PUBLIC_KEY_FILE_NAME"
generate_keys "$SERVER_KEY_PATH" "$SERVER_PRIVATE_KEY" "$SERVER_PUBLIC_KEY"

# CLIENT_PRIVATE_KEY: Path where client private key file will exist
# CLIENT_PUBLIC_KEY: Path where client public key file will exist
CLIENT_PRIVATE_KEY="$CLIENT_KEY_PATH$CLIENT_PRIVATE_KEY_FILE_NAME"
CLIENT_PUBLIC_KEY="$CLIENT_KEY_PATH$CLIENT_PUBLIC_KEY_FILE_NAME"
generate_keys "$CLIENT_KEY_PATH" "$CLIENT_PRIVATE_KEY" "$CLIENT_PUBLIC_KEY"


echo "*** (3) Enabling IP forwarding ***"

delete_file_if_exists "$SYSCTLFILEPATH"

# Create /etc/sysctl.conf file with IP Forwarding enabled
echo "net.ipv4.ip_forward=1" | sudo tee -a "$SYSCTLFILEPATH" > /dev/null 

# Apply the changes
sudo sysctl -p 

# Verify the changes were applied
echo "Verifying changes to IP forwarding: "; sysctl net.ipv4.ip_forward 


echo "*** (4) Create wg0.conf file ***"

# CONF_FILE_PATH: Path where wg0.conf will live
# NETWORK_INTERFACE: Internet interface WireGuard will use
# SERVER_PRIVATE_KEY_STRING: String of server private key file that was created
# CLIENT_PUBLIC_KEY_STRING: String of client private key file that was created
CONF_FILE_PATH="$WIREGUARDPATH/wg0.conf" 
NETWORK_INTERFACE=$(ip route show default | awk '{print $5; exit}') 
SERVER_PRIVATE_KEY_STRING=$(sudo cat "$SERVER_PRIVATE_KEY" | awk '{print $1; exit}') 
CLIENT_PUBLIC_KEY_STRING=$(sudo cat "$CLIENT_PUBLIC_KEY" | awk '{print $1; exit}')

delete_file_if_exists "$CONF_FILE_PATH"

# Create wg0.conf
sudo tee "$CONF_FILE_PATH" > /dev/null <<EOF
[Interface]
Address = 10.8.0.1/24
ListenPort = $FORWARDED_PORT
PrivateKey = $SERVER_PRIVATE_KEY_STRING

PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $NETWORK_INTERFACE -j MASQUERADE
PostDown =  iptables -D FORWARD -i wg0 -j  ACCEPT; iptables -D FORWARD -o wgo -j ACCEPT; iptables -t nat -D POSTROUTING -o $NETWORK_INTERFACE -j MASQUERADE

[Peer]
PublicKey = $CLIENT_PUBLIC_KEY_STRING
AllowedIPs = 10.8.0.2/32
EOF

echo "*** (5) Turn on wireguard ***"

# Enable WireGuard to auto-launch upon start or reboot of machine.
if sudo systemctl is-enabled --quiet wg-quick@wg0; then
	echo "wg-quick@wg0 is already enabled."
else
	echo "wg-quick@wg0 is disabled, enabling it so it can launch automatically on startup"
	sudo systemctl enable wg-quick@wg0
fi

# If WireGuard is already on, let's turn it off
if sudo systemctl is-active --quiet wg-quick@wg0; then
	echo "wg-quick@wg0 is currently on. Restarting the service."
	sudo systemctl stop wg-quick@wg0
fi

# Turn on WireGuard
sudo systemctl start wg-quick@wg0

# Show the status of WireGuard
sudo systemctl status wg-quick@wg0 --no-pager
sudo wg show
