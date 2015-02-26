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
#   pivot team-status past <days> - show ticket numbers grouped by assignees in the past <days>
#   pivot introduce - pivot will introduce itself


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
  afterdate: "search.json?query=type:ticket+created>"

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

# get entire user info with user_id
zendesk_user = (msg, user_id, user_json) ->
  zendesk_request_get msg, "#{ticket_queries.users}/#{user_id}.json", (result) ->
    if result.error
      msg.send result.description
      return
    user_json result

# group tickets to users
# group tickets to users
group_tickets = (msg, results) ->
  if results.count <= 0
    return

  assigned_tickets = {}
  unassinged = 0
  for result in results
    if result.assignee_id?
      assignee_id = result.assignee_id
      if "#{assignee_id}" of assigned_tickets
        assigned_tickets["#{assignee_id}"] += 1
      else
        assigned_tickets["#{assignee_id}"] = 1
    else
      unassinged += 1

  # key: user_id, value: tickets number
  # TODO, send ticket number and link to chat
  msg.send "unassigned: #{unassinged} ticket(s)"
  for key, value of assigned_tickets
    console.log "key = #{key}, value = #{value} in assigned_tickets"
    zendesk_user msg, key, (user_json) ->
      name = user_json.user.name
      value = assigned_tickets[user_json.user.id]
      msg.send "#{name}: #{value} ticket(s)"

# translate ticket comment to English
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

        if parsed[2] == 'en'
          return

        # parsed = parsed[0] and parsed[0][0] and parsed[0][0][0]
        parsed_message = ""
        if parsed[0]
          i = 0
          while parsed[0][i]
            if parsed[0][i][0]
              parsed_message += parsed[0][i][0]
            i += 1

        if parsed_message
          parsed_message = parsed_message.replace(/<return>/g, "\n")
          output = "\n ------#{comment_id}------- \nOriginal COMMENT:\n#{message}\n\n"
          output += "TRANSLATED TO:\n#{parsed_message}\n"
          msg.send output

# 1 => 01, 5 => 05
forceTwoDigits = (val) ->
  if val < 10
    return "0#{val}"
  return val


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

  #This is for the ascii art, not getting a suitable art so keeping it disabled
  #robot.router.get '/ascii.txt', (req, res) ->
  #  fs = require 'fs'
  #  indexfile = "#{__dirname}/public/ascii.txt"
  #  try
  #    data = fs.readFileSync indexfile, 'utf-8'
  #    if data
  #      res.end(data)
  #  catch error
  #    console.log('Unable to read file', error)


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

  # Return team-status show ticket numbers grouped by assignees in the past <days>
  # team-status past <days>
  robot.respond /team-status past ([\d]+)$/i, (msg) ->
    days = msg.match[1]
    if days <=0 || days > 90
      msg.send "Please input days between 0 and 91"
      return

    date = new Date()
    date = new Date(date.valueOf() - 1000 * 3600 * 24 * days)

    year = date.getFullYear()
    month = forceTwoDigits(date.getMonth()+1)
    day = forceTwoDigits(date.getDate())

    pastdate = date.getFullYear() + "-" + forceTwoDigits(date.getMonth()+1) + "-" + forceTwoDigits(date.getDate())
    zendesk_request_get msg, "#{ticket_queries.afterdate}#{pastdate}", (results) ->
      if results.count > 0
        msg.send "#{results.count} tickets created in past #{days} days"
        group_tickets msg, results.results

  # (all )?tickets
  robot.respond /(all )?tickets$/i, (msg) ->
    zendesk_request_get msg, ticket_queries.unsolved, (results) ->
      ticket_count = results.count
      msg.send "There are #{ticket_count} unsolved tickets"
      #group_tickets msg, results.results

  # pending tickets
  robot.respond /pending tickets$/i, (msg) ->
    zendesk_request_get msg, ticket_queries.pending, (results) ->
      ticket_count = results.count
      msg.send "There are #{ticket_count} pending tickets"
      #group_tickets msg, results.results

  # new tickets
  robot.respond /new tickets$/i, (msg) ->
    zendesk_request_get msg, ticket_queries.new, (results) ->
      ticket_count = results.count
      msg.send "There are #{ticket_count} new tickets"
      #group_tickets msg, results.results

  # escalated tickets
  robot.respond /escalated tickets$/i, (msg) ->
    zendesk_request_get msg, ticket_queries.escalated, (results) ->
      ticket_count = results.count
      msg.send "There are #{ticket_count} escalated tickets"
      #group_tickets msg, results.results

  # open tickets
  robot.respond /open tickets$/i, (msg) ->
    zendesk_request_get msg, ticket_queries.open, (results) ->
      ticket_count = results.count
      msg.send "There are #{ticket_count} open tickets"
      #group_tickets msg, results.results

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

  # introduce
  robot.respond /introduce$/i, (msg) ->
    message = "******************************************************\n"
    message += "I'm Pivot a.k.a PIVotal robOT and\n"
    message += "I am at your service to get anything from Zendesk\n"
    message += "Ask 'pivot help' for supported commands\n"
    message += "******************************************************"
    msg.send message

  # thanks
  robot.respond /thanks$/i, (msg) ->
    msg.send "My pleasure, #{msg.message.user.name}!"

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
    console.log "inside robot.enter"
    if robot.name != msg.message.user.name
      console.log "inside logic for robot.enter"
      message = "#{msg.message.user.name}, Welcome to the room"
      console.log "room: #{msg.message.room}"

      if "#{process.env.HUBOT_ADAPTER}" == "hipchat"
        robot.messageRoom "#{msg.message.room}", message
      else
        robot.messageRoom "#{msg.message.room}", message
