#!/bin/bash


echo ""
echo 
# Check cURL command if available (required), abort if does not exists
type curl >/dev/null 2>&1 || { echo >&2 "Required curl but it's not installed. Aborting."; exit 1; }
apt install wireguard jq -y

echo

# environment variables
OVERLAY_ID="ec843b7cb8ec481f8b83e311a95bcaed"
DEVICE_ID="784366a9d378437583635c430815512f"
API_KEY="BC0B9f28FbD28CDC81c441A2db5Ea950"
EXPORT_CONF_LOCATION="/etc/wireguard/wg0.conf"
#EXPORT_CONF_LOCATION="client_a2_w0.conf"

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
echo "Address = 10.0.0.2/32" >> ${EXPORT_CONF_LOCATION}
echo "PrivateKey = EGBE8lD8ZylQADxyGRwsucyKeJrpU7r2mAEhFfMHA20=" >> ${EXPORT_CONF_LOCATION}
echo "ListenPort = 51820" >> ${EXPORT_CONF_LOCATION}
echo "" >> ${EXPORT_CONF_LOCATION}
response1=$(curl -s --request GET -H "${HEADER_CONTENTTYPE}" -H "${HEADER_APIKEY}" -H "${BEARER_HEADER}" ${URI_GET_CONFIG} >> ${EXPORT_CONF_LOCATION})
echo "Fetched the wconfig for device" ${DEVICE_ID} "of overlay" ${OVERLAY_ID} "and updated " ${EXPORT_CONF_LOCATION}
sed -i -e 's/Peer 1/Peer/g' ${EXPORT_CONF_LOCATION}
sed -i -e 's/Peer 2/Peer/g' ${EXPORT_CONF_LOCATION}


# UPDATE THE CONFIG OF CLIENT APP - THIS IS NOT RELATED TO WIREGUARD BUT WITH THE APP SETUP
CONFIG_FILE="/home/vagrant/client_app/config.json"

echo "{
        \"server_ip\":\"172.48.48.51\", 
        \"server_port\":\"8080\",
        \"log_file\":\"/var/log/client.log\"
    }" > ${CONFIG_FILE}


# up the qg0
wg-quick up wg0