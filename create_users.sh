#!/bin/bash

# Log file
LOG_FILE="/var/log/user_management.log"

# Secure passwords file
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Create log and password files if they don't exist
sudo mkdir -p /var/log /var/secure
sudo touch $LOG_FILE $PASSWORD_FILE
sudo chmod 600 $PASSWORD_FILE

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a $LOG_FILE > /dev/null
}

# Check if input file is provided
if [ -z "$1" ]; then
    echo "Usage: sudo ./create_users.sh <input_file>"
    exit 1
fi

# Read usernames and groups from the provided text file
while IFS=';' read -r username groups; do
    # Remove any leading/trailing whitespace
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | xargs)

    # Skip empty lines
    [ -z "$username" ] && continue

    # Create user and personal group
    sudo useradd "$username" -m -U
    log_message "User $username created"

    # Create additional groups if they don't exist and add user to groups
    IFS=',' read -ra group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        sudo groupadd -f "$group"
        sudo usermod -aG "$group" "$username"
        log_message "User $username added to group $group"
    done

    # Set permissions and ownership for home directory
    sudo chown "$username:$username" "/home/$username"

    # Generate a random password
    password=$(openssl rand -base64 12)
    echo "$username:$password" | sudo chpasswd

    # Store passwords securely in /var/secure/user_passwords.csv
    echo "$username,$password" | sudo tee -a $PASSWORD_FILE > /dev/null
done < "$1"

sudo chmod 600 $PASSWORD_FILE
log_message "User creation script completed."
