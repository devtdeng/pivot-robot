# Description:
#   Queries Zendesk for information about support tickets
#
# Configuration:
#   HUBOT_ZENDESK_USER
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
#   pivot search articles <query> - search zendesk articles with provided query string
#   pivot search tickets <query> - search zendesk tickets with provided query string
#   pivot comment <ticket id> <comments> - add internal comment to tickets, this won't be sent to submitter
#   pivot translate <ticket id> - translate tickets into English if it's other in languages

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

# GET /api/v2/..., make sure header is configured as application/json.
zendesk_request_put = (msg, url, data, handler) ->
  zendesk_user = "#{process.env.HUBOT_ZENDESK_USER}"
  zendesk_apitoken = "#{process.env.HUBOT_ZENDESK_APITOKEN}"
  auth = new Buffer("#{zendesk_user}/token:#{zendesk_apitoken}").toString('base64')
  zendesk_url = "https://#{process.env.HUBOT_ZENDESK_SUBDOMAIN}.zendesk.com/api/v2"

  console.log "http request: #{zendesk_url}/#{url}"

  json = JSON.stringify(data)
  msg.http("#{zendesk_url}/#{url}")
    .headers(Authorization: "Basic #{auth}", Accept: "application/json", "Content-Type": "application/json")
    .put(json) (err, res, body) ->
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

# implement this to find out the user or email to use while posting
# internal message to tickets
zendesk_user = (msg, user_id) ->
  zendesk_request_get msg, "#{queries.users}/#{user_id}.json", (result) ->
    if result.error
      msg.send result.description
      return
    result.user

google_translate = (msg, comment_id, message) ->
  new_message = message.replace(/\n/g, "<return>")

  msg.http("https://translate.google.com/translate_a/t")
    .query({
      client: 't'
      hl: 'en'
      multires: 1
      sc: 1
      sl: 'auto'
      ssel: 0
      tl: 'en'
      tsel: 0
      uptl: 'en'
      text: new_message
    })
    .header('User-Agent', 'Mozilla/5.0')
    .get() (err, res, body) ->
      data = body
      if data.length > 4 and data[0] == '['
        parsed = eval(data)
        parsed = parsed[0] and parsed[0][0] and parsed[0][0][0]
        if parsed
          parsed_formatted = parsed.replace(/<return>/g, "\n")
          output = "\n ------#{comment_id}------- \nOriginal COMMENT:\n#{message}\n\n"
          output += "TRANSLATED TO:\n#{parsed_formatted}\n"
          msg.send output

module.exports = (robot) ->

  # App home page, this is not must
  # http://<host>.<domain>/
  # may be replace this with gh-pages later
  robot.router.get '/', (req, res) ->
    fs = require 'fs'
    indexfile = "#{__dirname}/public/index.html"
    try
      data = fs.readFileSync indexfile, 'utf-8'
      if data
        res.end(data)
    catch error
      console.log('Unable to read file', error)

  # TODO: return tickets and articles help to resolve the ticket
  # suggest <ticket id>
  robot.respond /suggest ([\d]+)$/i, (msg) ->
    ticketid = msg.match[1]
    msg.send "not implemented yet"
    # step 1: get ticket title
    # step 2: search articles
    # step 3: search tickets (exclude this ticket)

  # Add internal comment to special ticket
  # comment <ticket id> <comment>
  robot.respond /comment ([\d]+) (.*)$/i, (msg) ->
    ticket_id = msg.match[1]
    comment = "Comment from #{msg.message.user.name}:\n #{msg.match[2]}"
    data =
      ticket:
        comment:
          public: false,
          body: comment

    zendesk_request_put msg, "#{ticket_queries.tickets}/#{ticket_id}.json", data, (result) ->
      if result.error?
        return
      else
        msg.send "Added comment to Zendesk successfully"

  # show ticket description as well as comment
  # ticket <ticket id>
  robot.respond /ticket ([\d]+)$/i, (msg) ->
    ticket_id = msg.match[1]
    message = ""
    zendesk_request_get msg, "#{ticket_queries.tickets}/#{ticket_id}.json", (result) ->
      if result.error
        msg.send result.description
        return

      message += "#{tickets_url}/#{result.ticket.id} (#{result.ticket.status.toUpperCase()})"
      message += "\nUPDATED: #{result.ticket.updated_at}"
      message += "\nCREATED: #{result.ticket.created_at}"
      message += "\nSUBJECT: #{result.ticket.subject}"

      zendesk_request_get msg, "#{ticket_queries.tickets}/#{ticket_id}/comments.json", (results) ->
        i = 0

        for comment in results.comments
          message += "\n\n------ COMMENT #{i++} ------\n"
          message += "AUTHOR: #{comment.author_id}, CREATED: #{comment.created_at}, PUBLIC: #{comment.public}\n"
          message += "COMMENT: #{comment.body}"

        msg.send message

  # translate a ticket into English if it is not
  # translate <ticket id>
  robot.respond /translate ([\d]+)$/i, (msg) ->
    ticket_id = msg.match[1]
    zendesk_request_get msg, "#{ticket_queries.tickets}/#{ticket_id}/comments.json", (results) ->
      i = 0
      msg.send "Translate ticket:#{ticket_id} to English"
      for comment in results.comments
        google_translate msg, i++, comment.body

  # search articles with keyword
  # search articles <keyword>
  robot.respond /search articles (.*)$/i, (msg) ->
    keyword = msg.match[1]
    zendesk_request_get msg, "#{article_queries}#{keyword}", (results) ->
      if results.count < 1
        msg.send "no related articles found"
        return
      for result in results.results
        msg.send "#{result.title}\n#{result.html_url}\n"

  # search tickets with keyword, currently support subject
  # search tickets <keyword>
  robot.respond /search tickets (.*)$/i, (msg) ->
    keyword = msg.match[1]
    zendesk_request_get msg, "#{ticket_queries.keyword}#{keyword}", (results) ->
      if results.count < 1
        msg.send "no related tickets found"
        return
      for result in results.results
        msg.send "#{result.id}: #{result.subject}\n#{tickets_url}/#{result.id}\n"

  # (all )?tickets
  robot.respond /(all )?tickets$/i, (msg) ->
    zendesk_request_get msg, ticket_queries.unsolved, (results) ->
      ticket_count = results.count
      msg.send "There are #{ticket_count} unsolved tickets"

  # pending tickets
  robot.respond /pending tickets$/i, (msg) ->
    zendesk_request_get msg, ticket_queries.pending, (results) ->
      ticket_count = results.count
      msg.send "There are #{ticket_count} unsolved tickets"

  # new tickets
  robot.respond /new tickets$/i, (msg) ->
    zendesk_request_get msg, ticket_queries.new, (results) ->
      ticket_count = results.count
      msg.send "There are #{ticket_count} new tickets"

  # escalated tickets
  robot.respond /escalated tickets$/i, (msg) ->
    zendesk_request_get msg, ticket_queries.escalated, (results) ->
      ticket_count = results.count
      msg.send "There are #{ticket_count} escalated tickets"

  # open tickets
  robot.respond /open tickets$/i, (msg) ->
    zendesk_request_get msg, ticket_queries.open, (results) ->
      ticket_count = results.count
      msg.send "There are #{ticket_count} open tickets"

  # list (all )?tickets
  robot.respond /list (all )?tickets$/i, (msg) ->
    zendesk_request_get msg, ticket_queries.unsolved, (results) ->
      msg.send "There are #{results.count} tickets. \n ----------------------------- \n"
      for result in results.results
        msg.send "Ticket #{result.id} is #{result.status}: #{tickets_url}/#{result.id}  #{result.subject}"

  # list new tickets
  robot.respond /list new tickets$/i, (msg) ->
    zendesk_request_get msg, ticket_queries.new, (results) ->
      msg.send "There are #{results.count} new tickets. \n ----------------------------- \n"
      for result in results.results
        msg.send "Ticket #{result.id} is #{result.status}: #{tickets_url}/#{result.id}  #{result.subject}"

  # list pending tickets
  robot.respond /list pending tickets$/i, (msg) ->
    zendesk_request_get msg, ticket_queries.pending, (results) ->
      msg.send "There are #{results.count} pending tickets. \n ----------------------------- \n"
      for result in results.results
        msg.send "Ticket #{result.id} is #{result.status}: #{tickets_url}/#{result.id}  #{result.subject}"

  # list escalated tickets
  robot.respond /list escalated tickets$/i, (msg) ->
    zendesk_request_get msg, ticket_queries.escalated, (results) ->
      msg.send "There are #{results.count} escalted tickets. \n ----------------------------- \n"
      for result in results.results
        msg.send "Ticket #{result.id} is escalated and #{result.status}: #{tickets_url}/#{result.id}  #{result.subject}"

  # list open tickets
  robot.respond /list open tickets$/i, (msg) ->
    zendesk_request_get msg, ticket_queries.open, (results) ->
      msg.send "There are #{results.count} open tickets. \n ----------------------------- \n"
      for result in results.results
        msg.send "Ticket #{result.id} is #{result.status}: #{tickets_url}/#{result.id}  #{result.subject}"

  # Open ticket information if someone mentioned ticket #ticket_id in the chat room
  robot.hear /ticket #([\d]+)$/i, (msg) ->
    ticket_id = msg.match[1]
    message = ""
    zendesk_request_get msg, "#{ticket_queries.tickets}/#{ticket_id}.json", (result) ->
      if result.error
        msg.send result.description
        return

      message += "#{tickets_url}/#{result.ticket.id} (#{result.ticket.status.toUpperCase()})"
      message += "\nUPDATED: #{result.ticket.updated_at}"
      message += "\nCREATED: #{result.ticket.created_at}"
      message += "\nSUBJECT: #{result.ticket.subject}"

      msg.send message


  #Welcome greeting on entry to support room
  robot.enter (msg) ->
    if robot.name != msg.message.user.name
      message = "#{msg.message.user.name}, Welcome to support room"
      robot.messageRoom process.env.HUBOT_HIPCHAT_ROOMS, message    
