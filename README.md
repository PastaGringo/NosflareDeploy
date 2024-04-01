# NosflareDeploy

https://github.com/PastaGringo/nosflare/assets/16828964/fb476a92-6458-4a76-9216-9451039ac886

BETA Simple script to deploy the Nosflare serverless Nostr relay to Cloudflare Worker.  
Still is still in development and may be integrated to Nosflare repo when going to Production.

The script won't update your Nosflare until you change the source Github repo for Nosflare.  
Will be useful to test the upgrade for the next Nosflare release.

## How to use

### Download and make the script executable
```
wget https://raw.githubusercontent.com/PastaGringo/nosflare/main/DeployNosflare.sh
chmod +x ./DeployNosflare.sh
```

### Run the script
```
./DeployNosflare.sh

-------------------------- NosflareDeploy v1.0 ---------------------------
    _   __           ______                ____             __           
   / | / /___  _____/ __/ /___  ____ ___  / __ \___  ____  / /___  __  __
  /  |/ / __ \/ ___/ /_/ / __ \/ __// _ \/ / / / _ \/ __ \/ / __ \/ / / /
 / /|  / /_/ (__  ) __/ / /_/ / /  /  __/ /_/ /  __/ /_/ / / /_/ / /_/ / 
/_/ |_/\____/____/_/ /_/\__,_/_/   \___/_____/\___/ .___/_/\____/\__, /  
                                                 /_/            /____/   
-------------------------- NosflareDeploy v1.0 ---------------------------

Current dir: /home/pastadmin/Apps/TEMP
Hide my infos: disabled

Checking if variables have been set INTO the script (how-to: nano ./DeployNosflare.sh) ...

❌ VAR $CLOUDFLARE_API_TOKEN    :
❌ VAR $relayURL                :
❌ VAR $relayInfo_name          :
❌ VAR $relayInfo_description   :
❌ VAR $relayInfo_pubkey        :
❌ VAR $relayInfo_contact       :
❌ VAR $relayInfo_pubkey        :

[ERROR] At least one variable is missing. You need to set all the variables before starting the script. Exiting. Bye
```

### Update the script variables for your infos
```
# Please update variables below before running the script
##################################################################################################
# You can create your API token from your Cloudflare account here: https://dash.cloudflare.com/profile/api-tokens
# Use template "Edit Cloudflare Workers" or create a custom one for workers
CLOUDFLARE_API_TOKEN=""
relayInfo_name=""
# Full domain of the relay. Ex: relay.domain.tld. You need to have the domain.tld zone available in your Cloudflare domain list.
relayURL=""
relayInfo_description=""
#pubkey hex format, you can use damus convertor to convert your npub to hex : https://damus.io/key/
relayInfo_pubkey=""
relayInfo_contact=""
relayIcon_URL=""
# Set to 1 if you need to hide your info during the wrangler whoami & CF API KEY display (maybe you want to record your session script?)
hide_whoami_infos=0
```

### How to upgrade your Nosflare relay with the script
```
nano ./DeployNosflare.sh
```

### Upgrade your Nosflare relay with the script 
BUG ⚠️ please see known bug below

Update the variable nosflare_remote_gh_repo to the official Nosflare github repo:
```
nosflare_remote_gh_repo="https://github.com/Spl0itable/nosflare"
```

Don't hesitate to open new issues if you find some bugs into the script ⚡

### Known bug

- 28/03/2024: You can't update your Nosflare relay by switching from this relay to https://github.com/Spl0itable/nosflare. You have to delete your Cloudflare Worker & KV and ./nosflare folder (everything basically) before starting the script with the new Github repo https://github.com/Spl0itable/nosflare. As the script git pull the local cloned repo, it will always clone this repo and not the new one.
  
- 28/03/2024 [RESOLVED] the compatibility_date located in the wrangler.toml needs to be updated every new deployment with the current date time. See: https://developers.cloudflare.com/workers/configuration/compatibility-dates/

