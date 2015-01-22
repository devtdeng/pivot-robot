# pibot

## Deployment
- $ git clone https://github.com/devtdeng/pibot.git
- $ cd pibot
- Configure hipchat/zendesk login manifest.yml with valid info
- $ cf login -a api.run.pivotal.io -u <user> -p <password> -o <org> -s <space>
- $ cf create-service rediscloud 25mb redis
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
