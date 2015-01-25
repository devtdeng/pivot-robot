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
#   hubot (all) tickets - returns the total count of all unsolved tickets. The 'all' keyword is optional.
#   hubot new tickets - returns the count of all new (unassigned) tickets
#   hubot open tickets - returns the count of all open tickets
#   hubot escalated tickets - returns a count of tickets with escalated tag that are open or pending
#   hubot pending tickets - returns a count of tickets that are pending
#   hubot list (all) tickets - returns a list of all unsolved tickets. The 'all' keyword is optional.
#   hubot list new tickets - returns a list of all new tickets
#   hubot list open tickets - returns a list of all open tickets
#   hubot list pending tickets - returns a list of pending tickets
#   hubot list escalated tickets - returns a list of escalated tickets
#   hubot ticket <ID> - returns information about the specified ticket
#   hubot search articles <query>- search zendesk articles with provided query string
#   hubot search tickets <query>- search zendesk tickets with provided query string
#   hubot suggest <ID> - suggest related tickets or KB which helps resolve the ticket
#   hubot reserve - this is reserved commands
#   hubot reserve - this is reserved commands
#   hubot reserve - this is reserved commands
#   hubot reserve - this is reserved commands
#   hubot reserve - this is reserved commands
#   hubot reserve - this is reserved commands

sys = require 'sys' # Used for debugging

# Ticket search
# GET /api/v2/search.json?query={search_string}
tickets_url = "https://#{process.env.HUBOT_ZENDESK_SUBDOMAIN}.zendesk.com/tickets"
ticket_queries =
  unsolved: "search.json?query=status<solved+type:ticket"
  open: "search.json?query=status:open+type:ticket"
  new: "search.json?query=status:new+type:ticket"
  escalated: "search.json?query=tags:escalated+status:open+status:pending+type:ticket"
  pending: "search.json?query=status:pending+type:ticket"
  tickets: "tickets"
  users: "users"
  keyword: "search.json?query=subject:"

# Article search
# GET /api/v2/help_center/articles/search.json?query={search_string}
article_queries = "/help_center/articles/search.json?query="

zendesk_request = (msg, url, handler) ->
  zendesk_user = "#{process.env.HUBOT_ZENDESK_USER}"
  # zendesk_password = "#{process.env.HUBOT_ZENDESK_PASSWORD}"
  # auth = new Buffer("#{zendesk_user}:#{zendesk_password}").toString('base64')
  zendesk_apitoken = "#{process.env.HUBOT_ZENDESK_APITOKEN}"
  auth = new Buffer("#{zendesk_user}/token:#{zendesk_apitoken}").toString('base64')
  zendesk_url = "https://#{process.env.HUBOT_ZENDESK_SUBDOMAIN}.zendesk.com/api/v2"

  console.log "http request: #{zendesk_url}/#{url}"

  msg.http("#{zendesk_url}/#{url}")
    .headers(Authorization: "Basic #{auth}", Accept: "application/json")
      .get() (err, res, body) ->
        if err
          msg.send "Zendesk says: #{err}"
          return

        content = JSON.parse(body)
        console.log "http response: #{content}"

        if content.error?
          if content.error?.title
            msg.send "Zendesk says: #{content.error.title}"
          else
            msg.send "Zendesk says: #{content.error}"
          return

        handler content

# FIXME this works about as well as a brick floats
zendesk_user = (msg, user_id) ->
  zendesk_request msg, "#{queries.users}/#{user_id}.json", (result) ->
    if result.error
      msg.send result.description
      return
    result.user


module.exports = (robot) ->

  robot.respond /search articles (.*)/i, (msg) ->
    keyword = msg.match[1]
    zendesk_request msg, "#{article_queries}#{keyword}", (results) ->
      for result in results.results
        msg.send "#{result.title}\n#{result.html_url}\n"

  # support subjects only now, will search contents in future
  robot.respond /search tickets (.*)/i, (msg) ->
    keyword = msg.match[1]
    zendesk_request msg, "#{ticket_queries.keyword}#{keyword}", (results) ->
      for result in results.results
        msg.send "#{result.id}: #{result.subject}\n#{tickets_url}/#{result.id}\n"

  robot.respond /(all )?tickets$/i, (msg) ->
    zendesk_request msg, ticket_queries.unsolved, (results) ->
      ticket_count = results.count
      msg.send "#{ticket_count} unsolved tickets"

  robot.respond /pending tickets$/i, (msg) ->
    zendesk_request msg, ticket_queries.pending, (results) ->
      ticket_count = results.count
      msg.send "#{ticket_count} unsolved tickets"

  robot.respond /new tickets$/i, (msg) ->
    zendesk_request msg, ticket_queries.new, (results) ->
      ticket_count = results.count
      msg.send "#{ticket_count} new tickets"

  robot.respond /escalated tickets$/i, (msg) ->
    zendesk_request msg, ticket_queries.escalated, (results) ->
      ticket_count = results.count
      msg.send "#{ticket_count} escalated tickets"

  robot.respond /open tickets$/i, (msg) ->
    zendesk_request msg, ticket_queries.open, (results) ->
      ticket_count = results.count
      msg.send "#{ticket_count} open tickets"

  robot.respond /list (all )?tickets$/i, (msg) ->
    zendesk_request msg, ticket_queries.unsolved, (results) ->
      for result in results.results
        msg.send "Ticket #{result.id} is #{result.status}: #{tickets_url}/#{result.id}"

  robot.respond /list new tickets$/i, (msg) ->
    zendesk_request msg, ticket_queries.new, (results) ->
      for result in results.results
        msg.send "Ticket #{result.id} is #{result.status}: #{tickets_url}/#{result.id}"

  robot.respond /list pending tickets$/i, (msg) ->
    zendesk_request msg, ticket_queries.pending, (results) ->
      for result in results.results
        msg.send "Ticket #{result.id} is #{result.status}: #{tickets_url}/#{result.id}"

  robot.respond /list escalated tickets$/i, (msg) ->
    zendesk_request msg, ticket_queries.escalated, (results) ->
      for result in results.results
        msg.send "Ticket #{result.id} is escalated and #{result.status}: #{tickets_url}/#{result.id}"

  robot.respond /list open tickets$/i, (msg) ->
    zendesk_request msg, ticket_queries.open, (results) ->
      for result in results.results
        msg.send "Ticket #{result.id} is #{result.status}: #{tickets_url}/#{result.id}"

  robot.respond /ticket ([\d]+)$/i, (msg) ->
    ticket_id = msg.match[1]
    zendesk_request msg, "#{ticket_queries.tickets}/#{ticket_id}.json", (result) ->
      if result.error
        msg.send result.description
        return
      message = "#{tickets_url}/#{result.ticket.id} ##{result.ticket.id} (#{result.ticket.status.toUpperCase()})"
      message += "\nUpdated: #{result.ticket.updated_at}"
      message += "\nAdded: #{result.ticket.created_at}"
      message += "\nDescription:\n-------\n#{result.ticket.description}\n--------"
      msg.send message
