# FIXME this doesn't work yet

require 'cron'

module.exports = (robot) ->
  cronJob = require('cron').CronJob
  # tz = 'America/Los_Angeles'
  # new cronJob('0 0 9 * * 1-5', workdaysNineAm, null, true, tz)
  new cronJob('0 */1 * * * *', everyOneMinute, null, true)
  new cronJob('0 */5 * * * *', everyFiveMinutes, null, true)

  room = "#{process.env.HUBOT_HIPCHAT_ROOMS}"

  everyFiveMinutes = ->
    robot.messageRoom room, 'I will nag you every 5 minutes'
  everyOneMinute = ->
    console.log "Cronjob everyOneMinute is invokded"
