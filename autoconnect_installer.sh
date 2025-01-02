#!/bin/bash

# Define paths and filenames
POST_SCRIPT="/usr/local/bin/send_post.sh"
DISPATCHER_SCRIPT="/etc/NetworkManager/dispatcher.d/mbh2_post_request.sh"
CREDENTIALS_FILE="/etc/mbh2_credentials"
HELPERS_DIR="$HOME/.helpers"
RESPONSE_LOG="$HELPERS_DIR/response.log"

# Prompt for username and password
read -p "Enter Username: " username
read -s -p "Enter Password: " password
echo

# Store username and password securely
echo "Saving credentials..."
sudo bash -c "echo -e \"USERNAME=$username\nPASSWORD=$password\" > $CREDENTIALS_FILE"
sudo chmod 600 $CREDENTIALS_FILE
echo "Credentials saved at $CREDENTIALS_FILE."

# Create helpers directory
echo "Creating helpers directory..."
mkdir -p "$HELPERS_DIR"
echo "Helpers directory created at $HELPERS_DIR."

# Create send_post.sh script
echo "Creating send_post.sh..."
sudo bash -c "cat > $POST_SCRIPT" <<EOF
#!/bin/bash

# Load credentials
source /etc/mbh2_credentials

# Redirect URL
redirurl="google.co.in"

# Target URL
url="http://172.20.28.1:8002/index.php?zone=hostelzone&redirurl=\$redirurl"

# Send POST request using curl
response=\$(curl -s -X POST "\$url" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "auth_user=\$USERNAME" \
    -d "auth_pass=\$PASSWORD" \
    -d "redirurl=\$redirurl" \
    -d "accept=login")

# Save response to log file
helpers_dir="\$HOME/.helpers"
mkdir -p "\$helpers_dir"
echo "\$response" > "\$helpers_dir/response.log"

# Display response
echo "Response saved to \$helpers_dir/response.log"
EOF

# Set permissions for send_post.sh
sudo chmod +x $POST_SCRIPT
echo "send_post.sh created at $POST_SCRIPT."

# Create dispatcher script
echo "Creating dispatcher script..."
sudo bash -c "cat > $DISPATCHER_SCRIPT" <<EOF
#!/bin/bash

# Dispatcher script for MBH2_WiFi
interface=\$1
event=\$2

# Target SSID
target_ssid="MBH2_WiFi"

# Run the script only if connected to the target SSID
if [ "\$event" == "up" ]; then
    current_ssid=\$(iwgetid -r) # Get the current SSID
    if [ "\$current_ssid" == "\$target_ssid" ]; then
        /usr/local/bin/send_post.sh
    fi
fi
EOF

# Set permissions for dispatcher script
sudo chmod +x $DISPATCHER_SCRIPT
echo "Dispatcher script created at $DISPATCHER_SCRIPT."

# Completion message
echo "Installation complete. The script will now run automatically when connected to MBH2_WiFi."
echo "Server responses will be saved to $RESPONSE_LOG."
