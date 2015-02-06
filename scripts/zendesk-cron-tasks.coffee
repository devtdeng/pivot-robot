
tickets_url = "https://#{process.env.HUBOT_ZENDESK_SUBDOMAIN}.zendesk.com/tickets"
rooms = "#{process.env.HUBOT_HIPCHAT_ROOMS}"
console.log rooms
roomlist = rooms.split(",")
#for room in roomlist
#  console.log room

robot_global = null

zendesk_message_rooms = (msg) ->
  for room in roomlist
    robot_global.messageRoom room, msg

zendesk_request_get = (url, handler) ->
  zendesk_user = "#{process.env.HUBOT_ZENDESK_USER}"
  # zendesk_password = "#{process.env.HUBOT_ZENDESK_PASSWORD}"
  # auth = new Buffer("#{zendesk_user}:#{zendesk_password}").toString('base64')
  zendesk_apitoken = "#{process.env.HUBOT_ZENDESK_APITOKEN}"
  auth = new Buffer("#{zendesk_user}/token:#{zendesk_apitoken}").toString('base64')
  zendesk_url = "https://#{process.env.HUBOT_ZENDESK_SUBDOMAIN}.zendesk.com/api/v2"

  console.log "http request: #{zendesk_url}/#{url}"

  robot_global.http("#{zendesk_url}/#{url}")
    .headers(Authorization: "Basic #{auth}", Accept: "application/json")
      .get() (err, res, body) ->
        if err
          zendesk_message_rooms("Zendesk says: #{err}")
          return

        console.log "http response: #{body}"
        content = JSON.parse(body)

        if content.error?
          if content.error?.title
            zendesk_message_rooms("Zendesk says: #{content.error.title}")
          else
            zendesk_message_rooms("Zendesk says: #{content.error}")
          return

        handler content

module.exports = (robot) ->
  cronJob = require('cron').CronJob
  robot_global = robot
  new cronJob("#{process.env.HUBOT_NEW_TICKET_CRON_EXPRESSION}", checkNewTicket, null, true)

checkNewTicket = ->
  console.log 'checkNewTicket invoked'

  zendesk_request_get "search.json?query=status:new+type:ticket", (results) ->
    if results.count < 1
      # no new tickets, don't send message to chat room unless debugging
      #zendesk_message_rooms("no new ticket(s)")
      return

    ticket_count = results.count
    message = "Total of #{ticket_count} new ticket(s)"
    zendesk_message_rooms(message)

    message = ""
    for result in results.results
      message += "Ticket #{result.id} is #{result.status}: #{tickets_url}/#{result.id} created at #{result.created_at}\n #{result.subject}\n"

    zendesk_message_rooms(message)
