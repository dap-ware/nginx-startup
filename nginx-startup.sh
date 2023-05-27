#!/bin/bash

# Function to print usage
usage() {
    echo "Usage: $0 -d domain -e email"
    echo "  -d  --domain-name  Set the domain name for the certificate"
    echo "  -e  --email        Set the email address for certificate registration and renewal notices"
    echo "  -h  --help         Display this help message"
}

# Parse command-line arguments
while (( "$#" )); do
    case "$1" in
        -d|--domain-name)
            if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                domain=$2
                shift 2
            else
                echo "Error: Argument for $1 is missing" >&2
                exit 1
            fi
            ;;
        -e|--email)
            if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                email=$2
                shift 2
            else
                echo "Error: Argument for $1 is missing" >&2
                exit 1
            fi
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*|--*=) # unsupported flags
            echo "Error: Unsupported flag $1" >&2
            exit 1
            ;;
        *) # preserve positional arguments
            PARAMS="$PARAMS $1"
            shift
            ;;
    esac
done
eval set -- "$PARAMS"

# Check if domain and email are set
if [ -z "$domain" ] || [ -z "$email" ]; then
    echo "Error: Both the domain and email are required."
    usage
    exit 1
fi

# Update packages
sudo apt-get update

# Install Nginx
sudo apt-get install -y nginx

# Start and enable Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Create Nginx server block file
echo "server {
    listen 80;
    server_name $domain www.$domain;

    location / {
        root /var/www/html;
        index index.html;
    }
}" | sudo tee /etc/nginx/sites-available/$domain

# Enable the server block
sudo ln -s /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/

# Check Nginx configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx

# Install certbot and the Nginx plugin
sudo apt-get install -y certbot python3-certbot-nginx

# Get the SSL certificate
sudo certbot --nginx -d $domain -d www.$domain --non-interactive --agree-tos --email $email

# Test certificate renewal
sudo certbot renew --dry-run
