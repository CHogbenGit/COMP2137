#!/bin/bash

#check if the script is run in root

if [ "$(whoami)" != "root" ]; then
	echo "Error: This script must be run as root."
	exit 1
fi
 
echo "Checking for apache2 and squid..."

#creating a funciton to install apache2 and squid

install_software()
{
	if ! dpkg -l | grep -q "$1"; then
		echo "Installing $1..."
		apt update && apt install -y "$1"
		echo "$1 installed successfully."
	else
		echo "$1 is already installed."
	fi
}

#ensure apache2 and squid are installed
install_software apache2
install_software squid

#enable and start apache2 and squid
systemctl enable apache2 && systemctl start apache2
systemctl enable squid && systemctl start squid

echo "Configuring Network settings..."

#defining the netplan file path
NETPLAN_FILE="/etc/netplan/10-lxc.yaml"

#netplan configuration backup if needed

if ! grep -q "192.168.16.21" "$NETPLAN_FILE"; then
	echo "Updating netplan configuration files..."
	sed -i.bak -e '/addresses:/ s/\[.*\]/[192.168.16.21]/' "$NETPLAN_FILE"
	netplan apply
	echo "Netplan updated with address 192.168.16.21 successfully..."
else
	echo "Netplan configuration is already correct."
fi

#updating the /etc/hosts to reflect server IP
if ! grep -q "192.168.16.21 server1" /etc/hosts; then
	echo "Updating /etc/hosts for server1 IP..."
	sed -i '/server1/d' /etc/hosts
	echo "192.168.16.21 server1" >> /etc/hosts
else
	echo "/etc/hosts already contains correct entry for server1."
fi

echo "Configuring user accounts..."

USERNAMES=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

for username in "${USERNAMES[@]}"; do
	if ! id "$username" &> /dev/null; then
		echo "Creating user $username..."
		useradd -m -s /bin/bash "$username"
		echo "User $username created."
	else
		echo "User $username already exists."
	fi

	#Setting up SSH keys for each user
	SSH_DIR="/home/$username/.ssh"
	AUTH_KEYS="$SSH_DIR/authorized_keys"
	mkdir -p "$SSH_DIR"
	chmod 700 "$SSH_DIR"

	if [[ "username" == "dennis" ]]; then
		echo "Adding SSH key for dennis with sudo privileges..."
		usermod -aG sudo "$username"
		echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt990x5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI carsen@pc200369007" >> "$AUTH_KEYS"
	fi

	#generate RSA and ED25518 keys for users without any
	if ! grep -q "$(cat "$AUTH_KEYS")" "$AUTH_KEYS"; then
		echo "generating SSH keys for $username..."
		ssh-keygen -t rsa -f "$SSH_DIR/id_rsa" -q -N ""
		ssh-keygen -t ed25519 -f "$SSH_DIR/id_ed25519" -q -N ""
		cat "$SSH_DIR/id_rsa.pub" "$SSH_DIR/id_ed25519.pub" >> "$AUTH_KEYS"
		chmod 600 "$AUTH_KEYS"
		chown -R "$username:$username" "$SSH_DIR"
		echo "SSH keys configured for $username."
	fi
done

echo "System Modifications Complete. Server configuration is verified and updated as needed."
