# Load variables from .env file
source "$(dirname "$0")/.env" 

# Load functions from functions.sh to use here
source ./functions.sh	  

echo "INSTRUCTIONS: "
echo "* Do not add .conf to the file name"
echo "* Alpha-numerics only"
read -p "New file name: " NEW_CONF_FILE_NAME

# NEW_CONF_FILE_PATH: Path where client configuration file will live
# CLIENT_PRIVATE_KEY: Path where WireGuard's client private key is
# SERVER_PUBLIC_KEY: Path where WireGuard's server public key is
# CLIENT_PRIVATE_KEY_STRING: String of Wireguard's client private key
# SERVER_PRIVATE_KEY_STRING: String of Wireguard's server private key
NEW_CONF_FILE_PATH="$CONN_KEY_PATH/$NEW_CONF_FILE_NAME.conf"
CLIENT_PRIVATE_KEY="$CLIENT_KEY_PATH$CLIENT_PRIVATE_KEY_FILE_NAME"
SERVER_PUBLIC_KEY="$SERVER_KEY_PATH$SERVER_PUBLIC_KEY_FILE_NAME"
CLIENT_PRIVATE_KEY_STRING=$(sudo cat "$CLIENT_PRIVATE_KEY" | awk '{print $1; exit}')
SERVER_PUBLIC_KEY_STRING=$(sudo cat "$SERVER_PUBLIC_KEY" | awk '{print $1; exit}')

echo "*** Creating new file $NEW_CONF_FILE_PATH ***"
create_directory "$CONN_KEY_PATH"
delete_file_if_exists "$NEW_CONF_FILE_PATH"

# Create the client .conf file
sudo tee "$NEW_CONF_FILE_PATH" > /dev/null <<EOF
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY_STRING
Address = 10.8.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = $SERVER_PUBLIC_KEY_STRING
EndPoint = $PUBLIC_IP:$FORWARDED_PORT
AllowedIps = 10.8.0.0/24, $LAN_ALLOWED_IP
PersistentKeepalive = 25
EOF

# Generate QR code to scan for mobile
sudo qrencode -t ansiutf8 < "$NEW_CONF_FILE_PATH"
