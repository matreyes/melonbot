# Description
#   A hubot script for miscellaneous Slack utilities.
#
# Configuration:
#   HUBOT_SLACK_TOKEN
#   HUBOT_BOT_NAME
#
# Commands:
#   slack delete last [<count>] - <Delete the last (N) Hubot posts in the current room or group>
#
# Author:
#   brianantonelli <brian.antonelli@autotrader.com>

request = require('request')
token = process.env.HUBOT_SLACK_TOKEN
botname = process.env.HUBOT_BOT_NAME
baseURL = 'https://slack.com/api'

getHistory = (channel, msg, cb) ->
  if (channel.substr(0,1) == "G")
    request.get {url: "#{baseURL}/groups.history?token=#{token}&channel=#{channel}&count=15", json: true}, (err, res, history) ->
      throw err if err
      cb history, msg
  else
    request.get {url: "#{baseURL}/channels.history?token=#{token}&channel=#{channel}&count=15", json: true}, (err, res, history) ->
      throw err if err
      cb history, msg

getUserId = (username, cb) ->
  request.get {url: "#{baseURL}/users.list?token=#{token}", json: true}, (err, res, users) ->
    throw err if err
    userid = (user for user in users.members when user.name is username)[0]
    cb userid.id

deleteMessage = (channel, ts) ->
  console.log "Deleting #{ts} on #{channel}"
  request.post {url: "#{baseURL}/chat.delete?token=#{token}&channel=#{channel}&ts=#{ts}", json: true}, (err, res, deleted) ->
    throw err if err
    console.log deleted

# Find Hubot's ID
hubotid = null
getUserId botname, (uid) ->
  hubotid = uid

apologies = [
  'Me castigo jefecito :skull:',
  'Nunca mas, looooo juro :mouse:',
  'SYSTEM ERROR 83764-E, 0A: INVALID TASK STATE SEGMENT FAULT ... \nno, mentira, ya lo borré :P',
  'Esta bien, borro mi último mensaje, pero conste que solo sigo órdenes :robot_face:',
  'Pero explicame, ¿por que me mandas a escribir esas malas palabras?',
  'Lo borré, pero siempre vivirá en nuestras mentes y corazones :two_hearts:',
  'Mensaje, vuela alto :airplane:',
  'Toda evidencia ha sido completamente destruída :gun: :sunglasses:',
]
module.exports = (robot) ->

  robot.respond /.*borra\w*\s?(\d+)?/i, (msg) ->
    count = msg.match[1]
    if not count then count = 1
    if count > 5
      msg.send '¿por que quieres borrar tanto? ¡¡me niego rotundamente!!'
    else
      # `Prueba` channel name
      # channel = 'G0KAB6CRK'
      channel = msg.message.room
      robot.logger.info 'channel:', channel

      getHistory channel, msg, (history, res) ->
        if history.messages is undefined
          res.send 'No hay nada que borrar'
        else
          messages = (message for message in history.messages when message.user is hubotid)
          messages = messages.slice 0, count
          for msg, i in messages
            robot.logger.info 'Borrando:', msg.text
            robot.logger.info 'Borrando:', msg.text
            deleteMessage  channel, msg.ts
          setTimeout (->
            res.send res.random(apologies)
          ), 1000
