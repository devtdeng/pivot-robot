# Description:
#   Queries Zendesk for information about support tickets
#
# Configuration:
#   HUBOT_ZENDESK_USER
#   HUBOT_ZENDESK_PASSWORD
#   HUBOT_ZENDESK_APITOKEN
#   HUBOT_ZENDESK_SUBDOMAIN
#
# Commands:
#   hubot suggest <ticket id> - suggest related tickets or KB which helps resolve the ticket

module.exports = (robot) ->
  # suggest related tickets and articles for resolving support request ticket
  robot.respond /suggest ([\d]+)$/i, (msg) ->
    ticketid = msg.match[1]
    msg.send 'suggest is not implemented yet'
    # zendesk_request_get msg, "#{article_queries}#{keyword}", (results) ->
    #   if results.count <= 1
    #     msg.send "no related articles found"
    #     return
    #   for result in results.results
    #     msg.send "#{result.title}\n#{result.html_url}\n"
