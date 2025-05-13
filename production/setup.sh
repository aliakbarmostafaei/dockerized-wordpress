#!/bin/bash
# Setup script for WordPress with Caddy, Cloudflare, and Bitnami images

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color


# Check if .env exists, if not create from template
if [ ! -f .env ]; then
    echo -e "${GREEN}Creating .env file from template...${NC}"
    cp .env.example .env
    echo -e "${YELLOW}Please edit the .env file with your specific configuration values${NC}"
    
    # Generate random admin password
    WORDPRESS_ADMIN_PASSWORD=$(tr -dc 'A-Za-z0-9!#$%&()*+,-./:;<=>?@[\]^_`{|}~' < /dev/urandom | head -c 16)
    sed -i "s/strong_wordpress_password_here/${WORDPRESS_ADMIN_PASSWORD}/" .env
    echo -e "${GREEN}Generated random WordPress admin password${NC}"
fi

# Check if WordPress admin password is set
WORDPRESS_ADMIN_PASSWORD=$(grep WORDPRESS_ADMIN_PASSWORD .env | cut -d '=' -f2)
if [ "$WORDPRESS_ADMIN_PASSWORD" = "strong_wordpress_password_here" ]; then
    # Generate random admin password
    NEW_PASSWORD=$(tr -dc 'A-Za-z0-9!#$%&()*+,-./:;<=>?@[\]^_`{|}~' < /dev/urandom | head -c 16)
    sed -i "s/strong_wordpress_password_here/${NEW_PASSWORD}/" .env
    echo -e "${GREEN}Generated random WordPress admin password${NC}"
fi

# Check if Cloudflare API token is set
CLOUDFLARE_API_TOKEN=$(grep CLOUDFLARE_API_TOKEN .env | cut -d '=' -f2)
if [ "$CLOUDFLARE_API_TOKEN" = "your_cloudflare_api_token_here" ]; then
    echo -e "${YELLOW}Error: Cloudflare API token not set in .env file${NC}"
    echo -e "${YELLOW}You must set a valid Cloudflare API token before starting the containers${NC}"
    exit 1
fi

# Check if domain name is set
DOMAIN_NAME=$(grep DOMAIN_NAME .env | cut -d '=' -f2)
if [ "$DOMAIN_NAME" = "your-domain.com" ]; then
    echo -e "${YELLOW}Error: Domain name is not set in .env file${NC}"
    echo -e "${YELLOW}You must set a valid domain name before starting the containers${NC}"
    exit 1
fi

# Generate random WordPress table prefix
if grep -q "WORDPRESS_TABLE_PREFIX=wp_" .env; then
    RANDOM_PREFIX="wp_$(tr -dc 'a-z0-9' < /dev/urandom | head -c 6)_"
    echo -e "${GREEN}Generating random table prefix: ${RANDOM_PREFIX}${NC}"
    sed -i "s/WORDPRESS_TABLE_PREFIX=wp_/WORDPRESS_TABLE_PREFIX=${RANDOM_PREFIX}/" .env
fi

# Generate random path suffix for phpMyAdmin
if grep -q "PHPMYADMIN_PATH=phpmyadmin" .env; then
    RANDOM_PREFIX="phpmyadmin-$(tr -dc 'a-z0-9' < /dev/urandom | head -c 6)_"
    echo -e "${GREEN}Generating random path suffix for phpMyAdmin: ${RANDOM_PREFIX}${NC}"
    sed -i "s/PHPMYADMIN_PATH=phpmyadmin/PHPMYADMIN_PATH=${RANDOM_PREFIX}/" .env
fi

# Build custom Caddy image
echo -e "${GREEN}Building Caddy Docker image with extra modules...${NC}"
docker build -t caddy -f Dockerfile.caddy .

# Display WordPress admin credentials
WORDPRESS_ADMIN_USERNAME=$(grep WORDPRESS_ADMIN_USERNAME .env | cut -d '=' -f2)
WORDPRESS_ADMIN_PASSWORD=$(grep WORDPRESS_ADMIN_PASSWORD .env | cut -d '=' -f2)
WORDPRESS_DB_USER=$(grep WORDPRESS_DB_USER .env | cut -d '=' -f2)
WORDPRESS_DB_PASSWORD=$(grep WORDPRESS_DB_PASSWORD .env | cut -d '=' -f2)
DOMAIN_NAME=$(grep DOMAIN_NAME .env | cut -d '=' -f2)
PHPMYADMIN_PATH=$(grep PHPMYADMIN_PATH .env | cut -d '=' -f2)

echo -e "${GREEN}Setup complete!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Make sure all settings in the .env file are correct"
echo -e "2. Run 'docker-compose up -d' to start the containers"
echo -e "3. Configure Cloudflare SSL/TLS settings to 'Full (Strict)'"
echo -e "4. Access your WordPress site at https://${DOMAIN_NAME}"
echo -e "${YELLOW}WordPress admin credentials:${NC}"
echo -e "Username: ${WORDPRESS_ADMIN_USERNAME}"
echo -e "Password: ${WORDPRESS_ADMIN_PASSWORD}"
echo -e "Login URL: https://${DOMAIN_NAME}/wp-admin"
echo -e "=========================================="
echo -e "${YELLOW}phpMyAdmin credentials:${NC}"
echo -e "Username: ${WORDPRESS_DB_USER}"
echo -e "Password: ${WORDPRESS_DB_PASSWORD}"
echo -e "Login URL: https://${DOMAIN_NAME}/${PHPMYADMIN_PATH}/"

