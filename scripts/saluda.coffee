# Description:
#   Hubot saluda cuando hay gente nueva por DM
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   None
#
# Author:
#   @jorgeepunan

module.exports = (robot) ->
  robot.enter (msg) ->
    general = robot.adapter.client.rtm.dataStore.getChannelByName '#general'
    if msg.message.room == general.id
      robot.send {room: msg.message.user.id}, "¡Hola, *#{msg.message.user.name}*! :wave: \n
        Soy #{robot.name} el :robot: de este grupo y te doy la bienvenida a *Meloncargo*.\n\n

        Entre los canales que te pueden interesar están: \n
          - #desarrollo: Info interesante para computines.\n
          - #productos: Canal.\n
          - #random: todo lo que no cabe en otros canales, o que puede ir en todos, va aquí. Generalmente el canal con más movimiento y para procrastinar.\n\n

        Te sugiero presentarte en #general y te daremos la bienvenida como corresponde. Para conocer mis comandos puedes enviarme un `help` por DM o decir `melonbot help` en algún canal y te mostraré lo que puedo hacer.\n\n

        ¡Esperamos tu participación!"
