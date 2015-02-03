
tickets_url = "https://#{process.env.HUBOT_ZENDESK_SUBDOMAIN}.zendesk.com/tickets"
room = "#{process.env.HUBOT_HIPCHAT_ROOMS}"
robot_global = null

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
          robot_global.messageRoom room "Zendesk says: #{err}"
          return

        console.log "http response: #{body}"
        content = JSON.parse(body)

        if content.error?
          if content.error?.title
            robot_global.messageRoom room "Zendesk says: #{content.error.title}"
          else
            robot_global.messageRoom room "Zendesk says: #{content.error}"
          return

        handler content

module.exports = (robot) ->
  cronJob = require('cron').CronJob
  robot_global = robot

  # since the demo is lese than 3 minutes, set interval as 1 minute
  # Will create new ticket during the demo
  new cronJob('0 * * * * *', checknewticket, null, true)
  # new cronJob('0 */5 * * * 1-5', checknewticket, null, true)

checknewticket = ->
  console.log 'checknewticket invoked'

  zendesk_request_get "search.json?query=status:new+type:ticket", (results) ->
    if results.count < 1
      # no new tickets, don't send message to chat room
      return

    ticket_count = results.count
    robot_global.messageRoom room, "Total of #{ticket_count} new ticket(s)"

    message = ""
    for result in results.results
      message += "Ticket #{result.id} is #{result.status}: #{tickets_url}/#{result.id} created at #{result.created_at}\n #{result.subject}\n"
    robot_global.messageRoom room, message
