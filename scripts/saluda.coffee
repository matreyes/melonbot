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
          - #general: Preguntas generales sobre trabajo u otro . El canal con más movimiento.\n\n
          - #productos: Canal para hacerme consultas por los productos a publicar en Mercado Libre.\n
          - #desarrollo: Info relacionada con las plataformas meloncargo (Quokka, Numbat, Melonbot, etc.). Info interesante solo para computines.\n
          - #random: Todo lo que no cabe en otros canales, o que puede ir en todos, va aquí.\n\n

        Te sugiero presentarte en #general y te daremos la bienvenida como corresponde.
        Para conocer mis comandos puedes enviarme un `help` por DM o decir `melonbot help` en algún canal y te mostraré lo que puedo hacer.\n\n

        ¡Esperamos tu participación!"
