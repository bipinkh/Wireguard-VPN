#!/bin/bash


echo ""
echo 
# Check cURL command if available (required), abort if does not exists
type curl >/dev/null 2>&1 || { echo >&2 "Required curl but it's not installed. Aborting."; exit 1; }
apt install wireguard jq -y

echo

# environment variables
OVERLAY_ID="431165ef939e46d090a04882331c33ef"
DEVICE_ID="ed8281b136004f07a8aa1db17f6e3fe4"
API_KEY="BC0B9f28FbD28CDC81c441A2db5Ea950"
EXPORT_CONF_LOCATION="/etc/wireguard/wg0.conf"
#EXPORT_CONF_LOCATION="server_b_w0.conf"

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
echo "Address = 10.0.1.3/32" >> ${EXPORT_CONF_LOCATION}
echo "PrivateKey = 8DYQ5qUsUUi2ByQ99cIsgWFugqRLS5+TK+immfFpm2s=" >> ${EXPORT_CONF_LOCATION}
echo "ListenPort = 51820" >> ${EXPORT_CONF_LOCATION}
echo "" >> ${EXPORT_CONF_LOCATION}
response1=$(curl -s --request GET -H "${HEADER_CONTENTTYPE}" -H "${HEADER_APIKEY}" -H "${BEARER_HEADER}" ${URI_GET_CONFIG} >> ${EXPORT_CONF_LOCATION})
echo "Fetched the wconfig for device" ${DEVICE_ID} "of overlay" ${OVERLAY_ID} "and updated " ${EXPORT_CONF_LOCATION}
sed -i -e 's/Peer 1/Peer/g' ${EXPORT_CONF_LOCATION}
sed -i -e 's/Peer 2/Peer/g' ${EXPORT_CONF_LOCATION}


# up the qg0
wg-quick down wg0
wg-quick up wg0
wg0
# Track VPN connection
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
# Allowing incoming VPN traffic on the listening port
iptables -A INPUT -p udp -m udp --dport 51820 -m conntrack --ctstate NEW -j ACCEPT
# Allow both TCP and UDP recursive DNS traffic
iptables -A INPUT -s 10.200.200.0/24 -p tcp -m tcp --dport 53 -m conntrack --ctstate NEW -j ACCEPT
iptables -A INPUT -s 10.200.200.0/24 -p udp -m udp --dport 53 -m conntrack --ctstate NEW -j ACCEPT
# Allow forwarding of packets that stay in the VPN tunnel
iptables -A FORWARD -i wg0 -o wg0 -m conntrack --ctstate NEW -j ACCEPT
