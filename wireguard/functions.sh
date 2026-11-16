# Install apps
function install_app(){
	APP="$1"
	if dpkg -s "$APP" &> /dev/null; then
		echo "$APP is already installed"
	else
		echo "Installing $APP"
		sudo apt install -y "$APP"
	fi
}

# Create/re-create directories
function create_directory(){
	DIR="$1"
	if [ ! -d "$DIR" ]; then
		echo "Creating directory $DIR"
		sudo mkdir -p "$DIR"
	else
		echo "$DIR directory already exists"
	fi
}

# Remove file to re-write it if already exists
function delete_file_if_exists(){
	FILE="$1"
	if [ -f "$FILE" ]; then
		echo "$FILE already exists, will re-write it"
		sudo rm -f "$FILE"
	else
		echo "Creating file $FILE"
	fi
}

# Generate server/client public/private keys
function generate_keys(){
	KEY_PATH="$1"    # Private and public key file root directory
	PRIVATE_KEY="$2" # Private key file name
	PUBLIC_KEY="$3"  # Public key file name
	
	create_directory "$KEY_PATH"
	delete_file_if_exists "$PRIVATE_KEY"
	delete_file_if_exists "$PUBLIC_KEY"
	
	# Create the keys
	sudo bash -c "umask 077; wg genkey | tee $PRIVATE_KEY | wg pubkey > $PUBLIC_KEY"
	
	# Display their strings to the user.
	echo "Private Key: "; sudo cat "$PRIVATE_KEY"
	echo "Public Key: "; sudo cat "$PUBLIC_KEY"
}

