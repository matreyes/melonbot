# Description:
#   Tu secreto queda entre tú y :pudu:
#   Dile un secreto a @Pudu por DM y éste lo anunciará en el canal #random sin mencionarte.
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   None, it works by itself
#
# Author:
#   jorgeepunan

#introduccion = ["Nuevo secreto: ","Me acaban de contar que ","UH! Alguien me dijo que "]

module.exports = (robot) ->
  robot.respond /silencio?(.*)/i, (msg) -> #test local
    text = msg.match[1]
    if text.length > 0
      robot.messageRoom '#general', ":zipper_mouth_face: Alguien se quiere concentrar pero hay mucho ruido. Y dice: #{text}"
    else
      robot.messageRoom '#general', ":zipper_mouth_face: Alguien se quiere concentrar pero hay mucho ruido."

  robot.respond /problemas(.*)/i, (msg) -> #test local
    text = msg.match[1]
    robot.messageRoom '#general', "Estamos con problemas técnicos en este momento. #{text} Gracias por su comprensión :construction_worker:"

  robot.respond /resuelto/i, (msg) -> #test local
    robot.messageRoom '#general', "El sistema se encuentra operativo nuevamente. Gracias por su paciencia y comprensión. :quokka:"
