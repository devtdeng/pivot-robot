
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
  # tz = 'America/Los_Angeles'
  new cronJob('0 * * * * *', everyOneMinute, null, true)
  new cronJob('0 */15 * * * 1-5', workdays15Minutes, null, true)

# This is the actual check interval
workdays15Minutes = ->
  console.log 'working day, every 15 minute'
  robot_global.messageRoom room, 'working day, every 15 minutes'

# This is the check interval for demo
everyOneMinute = ->
  console.log 'every day, every 1 minute'
  robot_global.messageRoom room, 'every day, every 1 minute'  

  # because in most time, there are no new tickets, use pending/open for test 
  zendesk_request_get "search.json?query=status:new+type:ticket", (results) ->
    for result in results.results
      # TODO: There is error here, not able to 
      robot_global.messageRoom room "Ticket #{result.id} is #{result.status}: #{tickets_url}/#{result.id}"






