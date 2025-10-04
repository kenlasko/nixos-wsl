#!/bin/sh

# This is a script will create an action in Dead-Man-Hand to send my wife an email with my finanical info after I don't access Home Assistant for 2 weeks. If that happens, I'm presumed to be dead or incapacitated.
#
# I've configured Home Assistant via `Browser-Mod` to trigger an automation every time I visit Home Assistant to send an "I'm Alive" message to DMH.
# As long as I keep visiting Home Assistant at least once every 3 days, nothing should trigger.                                                                       
# If I don't visit Home Assistant for 3 days, DMH will start sending me daily emails until I either open Home Assistant (triggering the automation) or directly visit https://dmh.ucdialplans.com/api/alive. If I don't respond for a total of 2 weeks, the financial details email will be sent.
#                                                                                                                                                                      
# To modify the contents:
# 1. Edit the secrets.yaml using SOPS: `sops --config ~/nixos/.sops.yaml ~/nixos/config/secrets.yaml`
# 2. Search for the `dmh-email-message` secret                                                                                                                    
# 3. Make the necessary modifications and save the contents
# 4. Run `sudo nixos-rebuild switch` to update the decrypted file                                                                                                      
#                                                                                                                                                                      
# The action is already active in the pod. This script is only necessary if changes are made to the financial details. To replace the existing action:
# 1. EXEC into the `dead-man-hand-0` pod either via K9S or via `kubectl exec -it -n dmh dead-man-hand-0 -- sh`                                                         
# 1. Run `dmh-cli action ls` to get a list of current actions. There should be two. One is a reminder action. The other is the email to my wife
# 2. Find the UUID for the email action and run `dmh-cli action delete --uuid <ENTERUUIDHERE>`
# 3. From the base OS, run the ~/nixos/scripts/dmh-create-action.sh script with the updated instructions. You should get a message back that says `Action created succ>

EMAIL=$(cat /run/secrets/dmh-email-address)
SUBJECT="IMPORTANT: Financial notes"

JSON=$(jq -Rs --arg subject "$SUBJECT" \
              --arg dest "$EMAIL" \
              '{message: ., subject: $subject, destination: [$dest]}' < /run/secrets/dmh-email-message)

kubectl config use-context home
kubectl exec -n dmh dead-man-hand-0 -- \
dmh-cli action add --comment "DEATH EMAIL" --kind mail --process-after 336 --min-interval 0 --data "$JSON"
