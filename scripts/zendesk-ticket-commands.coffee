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
#   pivot (all) tickets - returns the total count of all unsolved tickets. The 'all' keyword is optional.
#   pivot new tickets - returns the count of all new (unassigned) tickets
#   pivot open tickets - returns the count of all open tickets
#   pivot escalated tickets - returns a count of tickets with escalated tag that are open or pending
#   pivot pending tickets - returns a count of tickets that are pending
#   pivot list (all) tickets - returns a list of all unsolved tickets. The 'all' keyword is optional.
#   pivot list new tickets - returns a list of all new tickets
#   pivot list open tickets - returns a list of all open tickets
#   pivot list pending tickets - returns a list of pending tickets
#   pivot list escalated tickets - returns a list of escalated tickets
#   pivot ticket <ticket id> - returns information about the specified ticket with comments
#   pivot search articles <query>- search zendesk articles with provided query string
#   pivot search tickets <query>- search zendesk tickets with provided query string
#   pivot add comment <ticket id> <comments> - add internal comment to tickets, this won't be sent to customers


# Used for debugging
#sys = require 'sys'
#fs   = require 'fs'
#path = require 'path'


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

zendesk_request_get = (msg, url, handler) ->
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

        console.log "http response: #{body}"
        content = JSON.parse(body)

        if content.error?
          if content.error?.title
            msg.send "Zendesk says: #{content.error.title}"
          else
            msg.send "Zendesk says: #{content.error}"
          return

        handler content


TODO: Complete this to post data to zendesk, need to use while posting comments
zendesk_request_put = (msg, url, data, handler) ->
  zendesk_user = "#{process.env.HUBOT_ZENDESK_USER}"
  # zendesk_password = "#{process.env.HUBOT_ZENDESK_PASSWORD}"
  # auth = new Buffer("#{zendesk_user}:#{zendesk_password}").toString('base64')
  zendesk_apitoken = "#{process.env.HUBOT_ZENDESK_APITOKEN}"
  auth = new Buffer("#{zendesk_user}/token:#{zendesk_apitoken}").toString('base64')
  zendesk_url = "https://#{process.env.HUBOT_ZENDESK_SUBDOMAIN}.zendesk.com/api/v2"

  console.log "http request: #{zendesk_url}/#{url}"

  msg.http("#{zendesk_url}/#{url}")
    .headers(Authorization: "Basic #{auth}", Accept: "application/json")
      .put(data) (err, res, body) ->
        if err
          msg.send "Zendesk says: #{err}"
          return

        # TODO
        msg.send "not implemented yet"


# TODO: implement this to find out the user or email to use while posting
# internal message to tickets
zendesk_user = (msg, user_id) ->
  zendesk_request_get msg, "#{queries.users}/#{user_id}.json", (result) ->
    if result.error
      msg.send result.description
      return
    result.user

module.exports = (robot) ->

  # App home page, this is not must
  # http://pivot-${random-word}.cfapps.io/
  # may be replace this with gh-pages later

  robot.router.get '/', (req, res) ->
    indexfile = '#{__dirname}public/index.html'
    try
      data = fs.readFileSync indexfile, 'utf-8'
      if data
        res.end(data)
    catch error
      console.log('Unable to read file', error)


  # TODO: add comment to special ticket, this doesn't work well now.
  # add comment <ticket id> <comment>
  # curl https://{subdomain}.zendesk.com/api/v2/tickets/{id}.json \
  #   -H "Content-Type: application/json" \
  #   -d '{"ticket": {"status": "solved", "comment": {"public": true, "body": "Thanks, this is now solved!"}}}' \
  #   -v -u {email_address}:{password} -X PUT

  robot.respond /add comment ([\d]+) (.*)$/i, (msg) ->
    ticket_id = msg.match[1]
    comment = msg.match[2]
    msg.send "not implemented yet"
    # zendesk_request_put msg, data, "#{ticket_queries.tickets}#{ticket_id}", (results) ->
    #   if result.error
    #     msg.send result.description


  # search articles with keyword
  # search articles <keyword>
  robot.respond /search articles (.*)$/i, (msg) ->
    keyword = msg.match[1]
    zendesk_request_get msg, "#{article_queries}#{keyword}", (results) ->
      if results.count <= 1
        msg.send "no related articles found"
        return
      for result in results.results
        msg.send "#{result.title}\n#{result.html_url}\n"

  # search tickets with keyword, currently support subject
  # search tickets <keyword>
  robot.respond /search tickets (.*)$/i, (msg) ->
    keyword = msg.match[1]
    zendesk_request_get msg, "#{ticket_queries.keyword}#{keyword}", (results) ->
      if results.count <= 1
        msg.send "no related tickets found"
        return
      for result in results.results
        msg.send "#{result.id}: #{result.subject}\n#{tickets_url}/#{result.id}\n"

  # (all )?tickets
  robot.respond /(all )?tickets$/i, (msg) ->
    zendesk_request_get msg, ticket_queries.unsolved, (results) ->
      ticket_count = results.count
      msg.send "#{ticket_count} unsolved tickets"

  # pending tickets
  robot.respond /pending tickets$/i, (msg) ->
    zendesk_request_get msg, ticket_queries.pending, (results) ->
      ticket_count = results.count
      msg.send "#{ticket_count} unsolved tickets"

  # new tickets
  robot.respond /new tickets$/i, (msg) ->
    zendesk_request_get msg, ticket_queries.new, (results) ->
      ticket_count = results.count
      msg.send "#{ticket_count} new tickets"

  # escalated tickets
  robot.respond /escalated tickets$/i, (msg) ->
    zendesk_request_get msg, ticket_queries.escalated, (results) ->
      ticket_count = results.count
      msg.send "#{ticket_count} escalated tickets"

  # open tickets
  robot.respond /open tickets$/i, (msg) ->
    zendesk_request_get msg, ticket_queries.open, (results) ->
      ticket_count = results.count
      msg.send "#{ticket_count} open tickets"

  # list (all )?tickets
  robot.respond /list (all )?tickets$/i, (msg) ->
    zendesk_request_get msg, ticket_queries.unsolved, (results) ->
      for result in results.results
        msg.send "Ticket #{result.id} is #{result.status}: #{tickets_url}/#{result.id}"

  # list new tickets
  robot.respond /list new tickets$/i, (msg) ->
    zendesk_request_get msg, ticket_queries.new, (results) ->
      for result in results.results
        msg.send "Ticket #{result.id} is #{result.status}: #{tickets_url}/#{result.id}"

  # list pending tickets
  robot.respond /list pending tickets$/i, (msg) ->
    zendesk_request_get msg, ticket_queries.pending, (results) ->
      for result in results.results
        msg.send "Ticket #{result.id} is #{result.status}: #{tickets_url}/#{result.id}"

  # list escalated tickets
  robot.respond /list escalated tickets$/i, (msg) ->
    zendesk_request_get msg, ticket_queries.escalated, (results) ->
      for result in results.results
        msg.send "Ticket #{result.id} is escalated and #{result.status}: #{tickets_url}/#{result.id}"

  # list open tickets
  robot.respond /list open tickets$/i, (msg) ->
    zendesk_request_get msg, ticket_queries.open, (results) ->
      for result in results.results
        msg.send "Ticket #{result.id} is #{result.status}: #{tickets_url}/#{result.id}"

  # ticket <ticket id>
  robot.respond /ticket ([\d]+)$/i, (msg) ->
    ticket_id = msg.match[1]
    message = ""
    zendesk_request_get msg, "#{ticket_queries.tickets}/#{ticket_id}.json", (result) ->
      if result.error
        msg.send result.description
        return
      message = "#{tickets_url}/#{result.ticket.id} ##{result.ticket.id} (#{result.ticket.status.toUpperCase()})"
      message += "\nUpdated: #{result.ticket.updated_at}"
      message += "\nAdded: #{result.ticket.created_at}"
      message += "\nDescription:\n-------\n#{result.ticket.description}\n--------"

    message += "\nComments:\n-------\n"
    zendesk_request_get msg, "#{ticket_queries.tickets}/#{ticket_id}/comments.json", (result) ->
      for result in results.results
        message += "author id: #{result.author_id}, created at #{result.created_at}\n"
        message += "body: #{result.body}\n\n"

    msg.send message

    
