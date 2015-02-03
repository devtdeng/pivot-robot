# Pivot

## What is it?
- Pivot a.k.a PIVotal roBOT is a [Hubot](https://hubot.github.com/) powered chat bot
- Pivot is currently configured to work with HipChat using the [Hubot HipChat adapter] (https://github.com/hipchat/hubot-hipchat)
- Pivot has different commands to interact with your configured [Zendesk] (https://www.zendesk.com/) instance 

## Deployment
- $ git clone https://github.com/devtdeng/pivot.git
- $ cd pivot
- Configure hipchat/zendesk login manifest.yml with valid info
- $ cf login -a api.run.pivotal.io -u <user> -p <password> -o <org> -s <space>
- $ cf push

## Test
- Login to hipchat with another account
- Talk to the user configured in manifest.yml
```
list open tickets

Ticket xxxx is open: https://<subdomain>.zendesk.com/tickets/xxxx
Ticket xxxx is open: https://<subdomain>.zendesk.com/tickets/xxxx
...
```
## Supported commands
