#!/bin/bash

fetch_admin_token() {
    read -p "Enter the API URL: " API_URL

    read -p "Enter the Username: " USER_NAME

    read -s -p "Enter the Password: " PASSWORD
    echo ""

    local url="${API_URL}/api/admin/token"
    local data="grant_type=password&username=${USER_NAME}&password=${PASSWORD}&scope=read write&client_id=your-client-id&client_secret=your-client-secret"

    response=$(curl -s -X POST "$url" \
        -H "accept: application/json" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "$data")

    # Check if curl request was successful
    if [ $? -ne 0 ]; then
        echo "Failed to fetch token"
        return 1
    fi

    token=$(echo $response | jq -r '.access_token')

    if [ "$token" != "null" ]; then
        echo "Token fetched successfully: $token"
        echo "$token"
    else
        echo "No access token found in the response."
        return 1
    fi
}

fetch_admin_token
