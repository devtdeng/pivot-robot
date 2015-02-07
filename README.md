# Pivot

## What is it?
- Pivot a.k.a PIVotal roBOT is a [Hubot](https://hubot.github.com/) powered chat bot
- The name came from the fact that it started as a part of [Pivotal's](http://www.pivotal.io) internal Hackathon
- Pivot is currently configured to work with HipChat using the [Hubot HipChat adapter] (https://github.com/hipchat/hubot-hipchat)
- Pivot has different commands to interact with your configured [Zendesk] (https://www.zendesk.com/) instance

## Deployment
- $ git clone https://github.com/devtdeng/pivot.git
- $ cd pivot
- Configure hipchat/zendesk login in manifest.yml with valid information
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
- pivot (all) tickets - returns the total count of all unsolved tickets. The 'all' keyword is optional
- pivot new tickets - returns the count of all new (unassigned) tickets
- pivot open tickets - returns the count of all open tickets
- pivot escalated tickets - returns a count of tickets with escalated tag that are open or pending
- pivot pending tickets - returns a count of tickets that are pending
- pivot list (all) tickets - returns a list of all unsolved tickets. The 'all' keyword is optional
- pivot list new tickets - returns a list of all new tickets
- pivot list open tickets - returns a list of all open tickets
- pivot list pending tickets - returns a list of pending tickets
- pivot list escalated tickets - returns a list of escalated tickets
- pivot ticket <ticket id> - returns information about the specified ticket with comments
- pivot search articles <query> - search zendesk articles with provided query string
- pivot search tickets <query> - search zendesk tickets with provided query string
- pivot comment <ticket id> <comments> - add internal comment to tickets, this won't be sent to submitter
- pivot translate <ticket id> - translate tickets into English if it's other in languages
- pivot team-status past <days> - return leaderboard show tickets grouped by assignees in past <days>
- pivot introduce - pivot will introduce itself

## Context commands and notifications
- Pivot will return the ticket link with some basic information if 'ticket #ticket_id' phrase is mentioned in the chat
- Pivot will check for new tickets in Zendesk (currently every 15 minutes and configurable in manifest.yml) and message the room if there are any new tickets

## Technical details
- Ready to deploy in [Pivotal Web Services](https://run.pivotal.io)(PWS)
- Hubot scripts written in [CoffeScript](http://coffeescript.org)

## Future plans
- Pivot will notify when a new ticket is cloe to resposne time limit
- Ticket sentiment analysis (see [this](https://github.com/samshull/sentiment-analysis) and [this](https://github.com/thisandagain/sentiment))
- Pivot will return the official CVE advisory if the CVE number is mentioned in the chat
- A command to check PWS status
- Pivot will support CF CLI and kind of act as [ChatOps](https://speakerdeck.com/jnewland/chatops-at-github)
