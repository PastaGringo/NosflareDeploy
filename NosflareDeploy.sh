#!/bin/bash
#
# # MANDATORY BEGIN ###########################################################################################
# Please update variables below before running the script
#  
# You can create your API token from your Cloudflare account here: https://dash.cloudflare.com/profile/api-tokens
# Use template "Edit Cloudflare Workers" or create a custom one for workers
CLOUDFLARE_API_TOKEN=""
relayInfo_name="" # example: relayInfo_name="My Beautiful domain!"
# Full domain of the relay. Ex: relay.domain.tld. You need to have the domain.tld zone available in your Cloudflare domain list.
relayURL="" # example: relayURL="relay.nostr.com"
relayInfo_description="" #example: I love french fries!
#pubkey hex format, you can use damus convertor to convert your npub to hex : https://damus.io/key/
relayInfo_pubkey="" #example: relayInfo_pubkey="b12b632c887f0c871d140d37bcb6e7c1e1a80264d0b7de8255aa1951d9e1ff79"
relayInfo_contact="" #example: relayInfo_contact="pastagringo@fractalized.net"
# MANDATORY END ###########################################################################################
#
# OPTIONAL BEGIN ##########################################################################################
relayIcon_URL=""
blockedPubkeys="" # Add comma separated kinds Ex: "c7f5948b5d80900046a67d8e3bf4971d6cba013abece1dd542eca223cf3dd3f", "fed5c0c3c8fe8f51629a0b39951acdf040fd40f53a327ae79ee69991176ba058", "e810fafa1e89cdf80cced8e013938e87e21b699b24c8570537be92aec4b12c18"
blockedEventKinds="" # Add comma separated kinds Ex: 1064, 4, 22242 ; Enable 1064 to avoid to reach the Cloudflare free tier limit!
# OPTIONAL END ##########################################################################################
#
# CUSTOM BEGIN ##########################################################################################
# Set to 1 if you need to hide your info during the wrangler whoami & CF API KEY display (maybe you want to record your session script?)
hide_whoami_infos=1
debug=0
# CUSTOM BEGIN ##########################################################################################
#
# ##################################################################################################
# Script variables, please do not modify if you don't know what you are doing
apps_to_check=(npm git jq)
vars_to_check_mandatory=(today worker_date CLOUDFLARE_API_TOKEN relayURL relayDOMAIN relayInfo_name relayInfo_description relayInfo_pubkey relayInfo_contact)
vars_to_check_optional=(relayIcon_URL blockedPubkeys blockedEventKinds )
pwd=$(pwd)
path_nosflare="$pwd/nosflare"
path_node_modules_bin="$path_nosflare/node_modules/.bin"
path_esbuild="$path_node_modules_bin/esbuild"
path_wrangler="$path_node_modules_bin/wrangler"
path_wrangler_toml="$path_nosflare/wrangler.toml"
path_worker_js="$path_nosflare/worker.js"
path_dist_worker_js="$path_nosflare/dist/worker.js"
nosflare_remote_gh_repo="https://github.com/spl0itable/nosflare"
url_file_wrangler_toml="https://raw.githubusercontent.com/PastaGringo/nosflare/main/wrangler.toml"
nosflare_gh_repo_owner=$(echo $nosflare_remote_gh_repo | cut -d"/" -f 4)
nosflare_remote_gh_repo_git="$nosflare_remote_gh_repo.git"
nosflare_kv_title="worker-kvdb"
relayDOMAIN=$(echo $relayURL | cut -d"." -f 2,3)
##################################################################################################
function echolor()
{
    YELLOW="\e[33m"
    ENDCOLOR="\e[0m"
    string=$(echo $1)
    echo -e "${YELLOW}${string}${ENDCOLOR}"
}
function HideWhoamiInfos
{
cat << EOF
 ⛅️ wrangler 3.39.0
-------------------
Getting User settings...
👋 You are logged in with an API Token, associated with the email Satoshi.Nakamoto@nostr.love!
┌─────────────────────────────────────┬──────────────────────────────────┐
│ Account Name                        │ Account ID                       │
├─────────────────────────────────────┼──────────────────────────────────┤
│ HIDDEN                              │ HIDDEN                           │
└─────────────────────────────────────┴──────────────────────────────────┘
🔓 To see token permissions visit https://dash.cloudflare.com/profile/api-tokens
EOF
}
##################################################################################################
clear
today=$(date +%Y-%m-%d)
worker_date=$(date --date="$today -1 day" +%Y-%m-%d) # CF bug when deploying outside US time
echo 
echo "-------------------------- NosflareDeploy v1.0 ---------------------------"
echo "    _   __           ______                ____             __           ";
echo "   / | / /___  _____/ __/ /___  ____ ___  / __ \___  ____  / /___  __  __";
echo "  /  |/ / __ \/ ___/ /_/ / __ \/ __// _ \/ / / / _ \/ __ \/ / __ \/ / / /";
echo " / /|  / /_/ (__  ) __/ / /_/ / /  /  __/ /_/ /  __/ /_/ / / /_/ / /_/ / ";
echo "/_/ |_/\____/____/_/ /_/\__,_/_/   \___/_____/\___/ .___/_/\____/\__, /  ";
echo "                                                 /_/            /____/.sh";
echo "-------------------------- NosflareDeploy v1.0 ---------------------------"
echo "                                                                $today    "
echo
echo "Current working dir   : $pwd"
if [[ $hide_whoami_infos -eq 1 ]]; then
    echo "Hide my infos         : enabled"
else
    echo "Hide my infos         : disabled"
fi
echo
echolor "Checking if basic depedencies are available ..."
echo
for app in ${apps_to_check[@]}; do
    echolor "Checking $app ..."
    if command -v $app &> /dev/null; then
        echo "✅ $app is installed "
    else
        echo ">>> $app is not installed ❌"
        echo ">>> Please install the application $app and run the script again."
        echo
        exit 1
    fi
done
echo
echolor "Checking if MANDATORY variables have been set INTO the script (how-to: nano ./NosflareDeploy.sh) ..."
if test -f "prod_vars"; then
    echo "### Loading Production variables ###"
    . prod_vars
fi
var_missing=0
for var in "${vars_to_check_mandatory[@]}"; do
    if [[ -z "${!var}" ]]; then
        #echo ">>> $var  = \"${!var}\""
        printf '❌ %-25s: %s\n' "$var " "${!var}"
        var_missing=1
        #exit 1
    else
        #echo ">>> $var ✅ = \"${!var}\""
        printf '✅ %-25s: %s\n' "$var " "${!var}"
    fi
done
if [ $var_missing -eq 1 ];then
    echo
    echolor '[ERROR] At least one variable is missing. You need to set all the variables before starting the script. Exiting. Bye'
    echo
    exit
fi
echo
echolor "Checking if OPTIONNAL variables have been set INTO the script (how-to: nano ./NosflareDeploy.sh) ..."
for var in "${vars_to_check_optional[@]}"; do
    if [[ -z "${!var}" ]]; then
        printf '⚠️  %-25s: %s\n' "$var " "${!var}"
    else
        printf '✅ %-25s: %s\n' "$var " "${!var}"
    fi
done
echo
echolor "Checking if Nosflare has already been built here ..."
if test -d $path_nosflare; then
    echo "✅ $path_nosflare has been found "
    echo
    echolor "Getting nosflare cloned version..."
    version_cloned=$(grep version $path_worker_js | cut -d '"' -f 2)
    version_cloned_last_commit=$(git -C $path_nosflare rev-parse HEAD)
    echo "Local cloned version found        : $version_cloned"
    echo "Local cloned latest commit found  : $nosflare_remote_gh_repo/commit/$version_cloned_last_commit"
    echo
    echolor "Getting nosflare latest version from github..."
    nosflare_latest_version=$(curl -s "https://raw.githubusercontent.com/$nosflare_gh_repo_owner/nosflare/main/worker.js" | grep version | cut -d '"' -f 2)
    echo "Remote latest version found       : $nosflare_latest_version"
    nosflare_remote_latest_commit=$(git ls-remote $nosflare_remote_gh_repo | grep HEAD | cut -f 1)
    echo "Remote latest commit              : $nosflare_remote_gh_repo/commit/$nosflare_remote_latest_commit"
    echo
    if [ "$version_cloned" = "$nosflare_latest_version" ]; then
        echo "You already have the latest version."
        echolor "Would you like to deploy Nosflare anyway?"
        echo
        echo "Press any key to continue or CTRL+C to quit this script."
        read
        echo "Sure?"
        read
    else
        echo "New Nosflare release available!"
        echolor "Would you like to update nosflare and rebuild it with your info?"
        echo "You'll have a functional worker.js file with your infos but if you made some code changes that WILL DELETE THEM."
        echo
        echo "Press any key to continue or CTRL+C to quit this script."
        read
        echo "Sure?"
        read
        echolor "Updating local folder with latest github changes from $nosflare_remote_gh_repo (MAIN branche) ..."
        echolor "Getting latest changes and overwriting local files..."
        git -C $path_nosflare reset --hard HEAD
        git -C $path_nosflare pull
        echo "Done ✅"
    fi
else
    echo "⚠️   $path_nosflare not found. First time install?"
    echo
    echolor "Would you like to clone nosflare from $nosflare_remote_gh_repo to $path_nosflare ?"
    echo
    echo "Press any key to continue or CTRL+C to exit."
    read
    echolor "Cloning Nosflare ..." # from $nosflare_remote_gh_repo to $path_nosflare ... "
    git clone --quiet $nosflare_remote_gh_repo_git
    echo "✅ clone succeed "
    echo
    echolor "Installing @noble/curves ..."
    npm install --silent --prefix $path_nosflare @noble/curves
    echo "✅ @noble/curves installation succeed "
    echo
    echolor "Installing wrangler-cli"
    npm install --silent --prefix $path_nosflare wrangler
    echo "✅  installation succeed"
fi
echo
echolor "Verifying if depedencies are locally installed ..."
echo
echolor "Checking wrangler ..."
if $path_wrangler --version &> /dev/null; then # TRY
    wrangler_version=$($path_wrangler --version)
    echo "✅ Found wrangler v$wrangler_version  "
else # CATCH
    echo
    echo "❌❌❌ Can't get wrangler version"
    echo "Please check your permissions to run wrangler."
    echo
    exit
fi
echo
echolor "Updating $path_worker_js with given ENV variables..."
sed -i 's/name: "Nosflare"/name: "'"$relayInfo_name"'"/g' $path_worker_js
sed -i 's/description: "A serverless Nostr relay through Cloudflare Worker and KV store"/description: "'"$relayInfo_description"'"/g' $path_worker_js
sed -i 's/pubkey: "d49a9023a21dba1b3c8306ca369bf3243d8b44b8f0b6d1196607f7b0990fa8df"/pubkey: "'"$relayInfo_pubkey"'"/g' $path_worker_js
sed -i 's/contact: "lucas@censorship.rip"/contact: "'"$relayInfo_contact"'"/g' $path_worker_js
sed -i 's#const relayIcon = "https://workers.cloudflare.com/resources/logo/logo.svg"#const relayIcon = "'"$relayIcon_URL"'"#g' $path_worker_js
sed -i 's/\[1064\]/\["'"$blockedEventKinds"'"\]/g' $path_worker_js
sed -i '/blockedEventKinds/s/"//g' $path_worker_js
sed -i '/3c7f5948b5d80900046a67d8e3bf4971d6cba013abece1dd542eca223cf3dd3f/,+2d' $path_worker_js
blockedEventKinds_raw=$(sed 's/"//g' <<< "$blockedEventKinds")
sed -i 's/  1064/  "'"$blockedEventKinds_raw"'"/g' $path_worker_js
sed -i '/  "'"$blockedEventKinds_raw"'"/s/"//g' $path_worker_js
sed -i '/3c7f5948b5d80900046a67d8e3bf4971d6cba013abece1dd542eca223cf3dd3f/,+2d' $path_worker_js
blockedPubkeys_count=$(grep -o ',' <<< "$blockedPubkeys" | wc -l)
blockedPubkeys_count=$((blockedPubkeys_count + 1))
i=1
for blockedPubkey in ${blockedPubkeys[@]}; do
    pubkey0=$(echo ${blockedPubkey:0:-1})
    pubkey='"'"$pubkey0"'"' 
    pubkey2=$(echo $pubkey | sed 's/$/,/')
    if [ "$i" -eq 1 ]; then
      sed -i '/const blockedPubkeys/a '"$pubkey"'' $path_worker_js
    else
      sed -i '/const blockedPubkeys/a '"$pubkey2"'' $path_worker_js
    fi 
    ((i++))
done
echo "✅ updated succeed"
echo
export CLOUDFLARE_API_TOKEN
echolor "Verifying who you are ..."
echo
if [[ $hide_whoami_infos -eq 1 ]]; then
    HideWhoamiInfos
else
    $path_wrangler whoami
fi
echo
echolor "Verify if wrangler.toml ($path_wrangler_toml) exists ..."
if test -f "$path_wrangler_toml"; then
    echo "✅ wrangler.toml exists "
else
    echo "⚠️   wrangler.toml doesn't exists! (normal, first install)"
    echolor "Dowloading it ($url_file_wrangler_toml)..."
    wget -q "$url_file_wrangler_toml" -O $path_wrangler_toml
    if test -f "$path_wrangler_toml"; then
        echo "✅ wrangler.toml download succeed"
    else
        echo ">>> Error during download"
        echo
        exit 1
    fi
fi
echo
echolor "Checking existing KV(s) from your Cloudflare account ..."
kvs_json=$($path_wrangler kv:namespace list)
kvs_count=$(echo $kvs_json | jq length)
if [[ $kvs_count -gt 0 ]]
    then
        echo "✅ Found $kvs_count KV(s)"
    else
        echo "⚠️   Found $kvs_count KV(s)"
        echo
        echolor "Creating Nosflare KV ... "
        echo
        $path_wrangler kv:namespace create kvdb
fi
echo
echolor "Looking for the KV-ID for KV with title $nosflare_kv_title ..."
kvs_json=$($path_wrangler kv:namespace list)
nosflare_cf_kv_id=$(echo $kvs_json | jq -r '.[] | select(.title | startswith("'"$nosflare_kv_title"'"))' | jq -r .id)
nosflare_cf_kv_title=$(echo $kvs_json | jq -r '.[] | select(.title | startswith("'"$nosflare_kv_title"'"))' | jq -r .title)
if [[ $debug -eq 1 ]]; then
    echo "[DEBUG] Listing KV namespace:"
    $path_wrangler kv:namespace list
    echo "[DEBUG] $nosflare_cf_kv_title -> $nosflare_cf_kv_id"
    echo "[DEBUG] End, Bye."
    exit 1
fi
if [ -z "${nosflare_cf_kv_id}" ]; then
    echo '❌ Cannot get the KV namespace ID'
    echo "Please, run the script one more time in case of Cloudflare timeout (good excuse, chief)."
    echo "If still not working, open a github issue!"
    echo
    exit 1
else
    echo "✅ Nosflare KVdb id : $nosflare_cf_kv_id"
fi
#exit
echo
echolor "Updating wrangler.toml file with given ENV variables... "
sed -i 's/"KV_ID"/"'"$nosflare_cf_kv_id"'"/g' $path_wrangler_toml
sed -i 's/"FULL_DOMAIN"/"'"$relayURL"'"/g' $path_wrangler_toml
sed -i 's/"DOMAIN"/"'"$relayDOMAIN"'"/g' $path_wrangler_toml
sed -i 's/"DATE"/"'"$worker_date"'"/g' $path_wrangler_toml
echo "✅ Done"
echo
echolor "Deploying your Nosflare Nostr relay to Cloudflare ..."
echo
if $path_wrangler deploy $path_worker_js
then
    echo
    echo "✅✅✅ Nosflare deployment succeed! 💥"
else
    echo
    echo "⛔ Nosflare deployment failed!"
    echo "Removing wrangler.toml file to not break NosflareDeploy"
    rm -rf $path_wrangler_toml
    echo "Something is wrong. Please open a github issue: https://github.com/PastaGringo/NosflareDeploy/issues/new/choose"
    echo
    exit
fi
echo
echolor "##################################### NOSFLARE DEPLOYMENT COMPLETE #####################################"
echo
echo "  Your Nosflare Nostr relay is available here   : https://$relayURL"
echo "  Your Nosflare Nostr websocket                 : wss://$relayURL"
echo "  Your can check your relay state here          : https://nostr.watch/relay/$relayURL"
echo
echolor "########################################################################################################"
echo
echo "                                              Happy Zaps ⚡"
echo
echo
echo
echo
echo
echo
echolor "############################################## DANGER ZONE #############################################"
echo
echolor "Press any key if you want to begin the process to delete your Cloudflare Worker, your Cloudflare KV and the local cloned Nosflare directory."
echo "Btw, you saw how quickly you can rebuild your Nosflare nostr relay, don't worry so much :)"
echo
echo "CTRL+C to quit."
read
echolor "Delete everything?"
read
echolor "Sure?"
read
echolor "REALLY Sure? Last chance to abort!"
read
echolor "Deleting the Cloudflare KV namespace ..."
echo
$path_wrangler kv:namespace delete --namespace-id $nosflare_cf_kv_id
echo "✅ Done "
echo
echolor "Deleting the Cloudflare Worker ..."
echo
$path_wrangler delete --config $path_wrangler_toml --force
echo "✅ Done "
echo
echolor "Checking if $path_nosflare still exists ..."
if test -d $path_nosflare; then
    echo ">>> Directory $path_nosflare exists."
    echolor "Removing it ..."
    rm -rf $path_nosflare
    echo "Removed ✅"
else
    echo "Weird, $path_nosflare is missing?!"
    echo "Nevermind, less to do."
fi
echo
echo ">>> Everything has been deleted ✅"
echo
echo "Bye!"
echo
