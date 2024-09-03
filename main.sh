#!/bin/bash

fetch_admin_token() {
    read -p "Enter the API URL: " API_URL
    read -p "Enter the Username: " USER_NAME
    read -s -p "Enter the Password: " PASSWORD
    echo "--------------------------------------------"

    local url="${API_URL}/api/admin/token"
    local data="grant_type=password&username=${USER_NAME}&password=${PASSWORD}&scope=read write&client_id=your-client-id&client_secret=your-client-secret"

    response=$(curl -s -X POST "$url" \
        -H "accept: application/json" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "$data")

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

get_all_users() {
    TOKEN=$(fetch_admin_token)
    if [ $? -ne 0 ]; then
        echo "Failed to get access token."
        return 1
    fi

    local api_url="${API_URL}/api/users"
    response=$(curl -s -X GET "$api_url" \
        -H "accept: application/json" \
        -H "Authorization: Bearer $TOKEN")

    if [ $? -ne 0 ]; then
        echo "Failed to fetch users"
        return 1
    fi

    content_type=$(echo "$response" | jq -r '. | if type=="object" then "application/json" else empty end')

    if [ "$content_type" == "application/json" ]; then
        users_data=$(echo "$response" | jq -c '.users[]')

        user_summaries=()

        for user in $users_data; do
            username=$(echo $user | jq -r '.username')
            sub_last_user_agent=$(echo $user | jq -r '.sub_last_user_agent')

            user_summary="{\"username\": \"$username\", \"sub_last_user_agent\": \"$sub_last_user_agent\"}"
            user_summaries+=("$user_summary")
        done

        echo "${user_summaries[@]}" | jq -s '.'
    else
        echo "Unexpected content type: $response"
        return 1
    fi
}

get_all_users
