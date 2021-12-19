#!/bin/bash


echo ""
echo 
# Check cURL command if available (required), abort if does not exists
type curl >/dev/null 2>&1 || { echo >&2 "Required curl but it's not installed. Aborting."; exit 1; }
apt install wireguard jq -y

echo

# environment variables
OVERLAY_ID="431165ef939e46d090a04882331c33ef"
DEVICE_ID="e82bec829c1a4f4498674284ac6c7390"
API_KEY="BC0B9f28FbD28CDC81c441A2db5Ea950"
EXPORT_CONF_LOCATION="/etc/wireguard/wg0.conf"
#EXPORT_CONF_LOCATION="client_b2_w0.conf"

# header components
HEADER_CONTENTTYPE="Content-Type: application/json"
HEADER_APIKEY="x-api-key: "${API_KEY}

# urls
HOST="http://meshmash.vikaa.fi:49324"
URI_GET_CONFIG=${HOST}"/overlays/"${OVERLAY_ID}"/devices/"${DEVICE_ID}"/wgconfig"
URI_GET_TOKEN=${HOST}"/devices/"${DEVICE_ID}"/token"
URI_PUT_IP=${HOST}"/devices/"${DEVICE_ID}




# GET THE TOKEN
echo "getting the token.."
response=$(curl -s --request GET -H "${HEADER_CONTENTTYPE}" -H "${HEADER_APIKEY}" ${URI_GET_TOKEN} | jq -r '.token')
echo $response
TOKEN=$response

echo "--------"

# GET THE CONFIG

BEARER_HEADER="Authorization: Bearer "${TOKEN}
echo "getting the wconfig.."
echo > ${EXPORT_CONF_LOCATION} #clear the file
echo "[Interface]" >> ${EXPORT_CONF_LOCATION}
echo "Address = 10.0.1.2/32" >> ${EXPORT_CONF_LOCATION}
echo "PrivateKey = +BX3k5Bksgmbl4FV2A9Cmx7PsYLO20M/vU8hB1qh0Fo=" >> ${EXPORT_CONF_LOCATION}
echo "ListenPort = 51820" >> ${EXPORT_CONF_LOCATION}
echo "" >> ${EXPORT_CONF_LOCATION}
response1=$(curl -s --request GET -H "${HEADER_CONTENTTYPE}" -H "${HEADER_APIKEY}" -H "${BEARER_HEADER}" ${URI_GET_CONFIG} >> ${EXPORT_CONF_LOCATION})
echo "Fetched the wconfig for device" ${DEVICE_ID} "of overlay" ${OVERLAY_ID} "and updated " ${EXPORT_CONF_LOCATION}
sed -i -e 's/Peer 1/Peer/g' ${EXPORT_CONF_LOCATION}
sed -i -e 's/Peer 2/Peer/g' ${EXPORT_CONF_LOCATION}


# UPDATE THE CONFIG OF CLIENT APP - THIS IS NOT RELATED TO WIREGUARD BUT WITH THE APP SETUP
CONFIG_FILE="/home/vagrant/client_app/config.json"

echo "{
        \"server_ip\":\"172.48.48.52\", 
        \"server_port\":\"8080\",
        \"log_file\":\"/var/log/client.log\"
    }" > ${CONFIG_FILE}

# up the qg0
wg-quick up wg0