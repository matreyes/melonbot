# Description
#   Script de hubot para seleccionar los participantes del amigo secreto
#
# Dependencies:
#   None
#
# Configuration:
#   AMIGO_SECRETO_MONTO
#
# Commands:
#   hubot amigo secreto iniciar -> Inicia el juego
#   hubot amigo secreto participar -> Indica que si quieres participar
#   hubot amigo secreto nica -> Indica que no quieres participar
#   hubot amigo secreto deseo -> Agregar regalos a tu lista de deseos
#   hubot amigo secreto que regalar a <username> -> Ver que desea un usuario
#   hubot amigo secreto sortear -> Sortear los amigos secretos
#   hubot amigo secreto reiniciar -> Sortear los amigos secretos
#   hubot amigo secreto participantes -> Ver los participantes
#   hubot amigo secreto mis deseos -> Ver tu lista de deseos
#
# Author:
#   lgaticaq

module.exports = (robot) ->
  onlyActiveUsers = (user) ->
    # return user.id == 'U2K30SM2T'
    return not user.deleted and not user.is_bot and user.name isnt "slackbot"

  secretSantaShuffle = (people) ->
    # From https://github.com/DKunin/secret-santa-shuffler/blob/master/index.js
    picks = {}
    convertToNumberIfNotString = (item) ->
      integ = parseInt(item)
      return if isNaN(integ) then item else integ
    loop
      receivers = Array.from(people)
      for i of people
        s = people[i]
        r = null
        loop
          if receivers.length == 1 and receivers[0] == s
            break
          j = Math.floor(Math.random() * receivers.length)
          if s != receivers[j]
            r = receivers[j]
            receivers.splice j, 1
          unless r == null
            break
        if r != null
          picks[s] = r
      unless Object.keys(picks).length < people.length
        break
    outputArray = []
    for sender of picks
      outputArray.push [
        convertToNumberIfNotString(sender)
        picks[sender]
      ]
    return outputArray

  startDraw = ->
    status = robot.brain.get("amigo-secreto:status")
    if status isnt "finish"
      robot.brain.set("amigo-secreto:status", "finish")
      brain = robot.brain.get("amigo-secreto:users")
      ids = brain.filter((x) -> x.participate).map((x) -> x.id)

      tuplas = secretSantaShuffle(ids)
      wishes = robot.brain.get("amigo-secreto:wishes") or []
      return robot.adapter.client.web.users.list()
        .then (data) ->
          users = data.members.filter((x) -> ids.indexOf(x.id) > -1)
          return tuplas.map (tupla) ->
            choice1 = users.find((x) -> x.id is tupla[0])
            choice2 = users.find((x) -> x.id is tupla[1])
            wishe1 = wishes.find((x) -> x.id is choice1.id)
            choice1.wishes = wishe1.wishes if typeof wishe1 isnt "undefined"
            wishe2 = wishes.find((x) -> x.id is choice2.id)
            choice2.wishes = wishe2.wishes if typeof wishe2 isnt "undefined"
            robot.brain.set("amigo-secreto:users", brain)
            return {user1: choice1, user2: choice2}
        .then (data) ->
          data.forEach (x) ->
            message = ":tada: #{x.user1.real_name or x.user1.name} " +
            "tu amigo secreto es #{x.user2.real_name or x.user2.name} :tada:"
            if typeof x.user2.wishes isnt "undefined"
              wishes = x.user2.wishes.map((x, i) -> "#{i + 1}) #{x}").join("\n")
              message += "\nTu amigo desea que le regales lo " +
              "siguiente:\n#{wishes}"
            else
              message += "\nTu amigo aún no ha deseado nada." +
              "\nPuedes consultar más tarde con el comando " +
              "`amigo secreto que regalar a #{x.user2.name}`"
            robot.adapter.client.web.chat.postMessage(
              x.user1.id, message, options)

  wishesFor = (user) ->
    wishes = robot.brain.get("amigo-secreto:wishes") or []
    return wishes.find((x) -> x.id is user.id)

  options = {as_user: true}

  robot.respond /amigo secreto iniciar$/i, (res) ->
    status = robot.brain.get("amigo-secreto:status")
    if status isnt "started"
      robot.brain.set("amigo-secreto:status", "started")
      robot.adapter.client.web.users.list()
        .then (data) ->
          users = []
          data.members.filter(onlyActiveUsers).forEach (x) ->
            # message = "*ATENCION. ESTE ES SOLO UN AMIGO SECRETO DE PRUEBA, NO ES EL REAL. DATE POR AVISAD@*\n"
            name = x.real_name or x.name
            message = "Hola #{name} ¿quieres participar " +
            "del amigo secreto?\n" +
            "De ser así respóndeme con `amigo secreto participar`\n" +
            "De lo contrario respóndeme con `amigo secreto nica`"
            robot.adapter.client.web.chat.postMessage x.id, message, options
            users.push(name)
          robot.messageRoom '#general', "Comenzó el sorteo de amigo secreto. Los invitados son:\n#{users.join('\n')}"
        .catch (err) ->
          robot.emit("error", err)

  robot.respond /amigo secreto participar$/i, (res) ->
    brain = robot.brain.get("amigo-secreto:users") or []
    user = brain.find((x) -> x.id is res.message.user.id)
    if typeof user is "undefined"
      user = {id: res.message.user.id, participate: true}
      brain.push(user)
    user.participate = true
    robot.brain.set("amigo-secreto:users", brain)
    message = ":tada: Felicitaciones :tada:\n" +
    "Una vez que todos confirmen, se procederá a realizar el sorteo.\n" +
    "Mientras tanto puedes agregar cosas que quieras recibir con el " +
    "comando `amigo secreto deseo <lo que quieras>`.\n" +
    "Puedes llamar el comando las veces que quieras y luego revisar con el" +
    "comando `amigo secreto mis deseos` cuales cosas has agregado."

    if process.env.AMIGO_SECRETO_MONTO
      message += "\nRecuerda que se acordó que los regalos fueran de un " +
      "*precio no mayor a $#{process.env.AMIGO_SECRETO_MONTO}*"
    res.send message

  robot.respond /amigo secreto nica$/i, (res) ->
    brain = robot.brain.get("amigo-secreto:users") or []
    user = brain.find((x) -> x.id is res.message.user.id)
    if typeof user is "undefined"
      user = {id: res.message.user.id, participate: false}
      brain.push(user)
    user.participate = false
    robot.brain.set("amigo-secreto:users", brain)
    res.send ":cry: ok, para la próxima sera :wave:"

  robot.respond /amigo secreto deseo (.+)$/i, (res) ->
    wish = res.match[1]
    wishes = robot.brain.get("amigo-secreto:wishes") or []
    user = wishes.find((x) -> x.id is res.message.user.id)
    if typeof user is "undefined"
      wishes.push
        id: res.message.user.id, wishes: [wish]
    else
      user.wishes.push(wish)
    robot.brain.set("amigo-secreto:wishes", wishes)
    res.send "Tu deseo ha sido almacenado :ok_hand:"

  robot.respond /amigo secreto que regalar a (\w+)$/i, (res) ->
    username = res.match[1]
    robot.adapter.client.web.users.list()
      .then (data) ->
        user = data.members.find((x) -> x.name is username)
        if user?
          wishes = robot.brain.get("amigo-secreto:wishes") or []
          wishe = wishes.find((x) -> x.id is user.id)
          if wishe?
            _wishes = wishe.wishes.map((x, i) -> "#{i + 1}) #{x}").join("\n")
            res.send(
              "#{user.real_name or user.name} desea que le regales " +
              "lo siguiente:\n#{_wishes}")
          else
            message = "#{username} aún no ha deseado " +
            "nada. Piensa en un buen :gift:"
            if process.env.AMIGO_SECRETO_MONTO
              message += "\nRecuerda que se acordó que los regalos fueran " +
              "de un *precio no mayor a $#{process.env.AMIGO_SECRETO_MONTO}*"
              res.send(message)

  robot.respond /amigo secreto sortear$/i, (res) ->
    res.send("Suerte y recuerda eligir un buen :gift:")
    startDraw()

  robot.respond /amigo secreto reiniciar$/i, (res) ->
    robot.brain.set("amigo-secreto:users", [])
    robot.brain.set("amigo-secreto:wishes", [])
    robot.brain.set("amigo-secreto:status", "")
    res.send("Limpieza lista :ok_hand:, ya puedes iniciar nuevamente")

  robot.respond /amigo secreto participantes$/i, (res) ->
    robot.adapter.client.web.users.list()
      .then (data) ->
        inUsers = []
        outUsers = []
        notConfirmed = []
        data.members.forEach (u) ->
          user = robot.brain.get("amigo-secreto:users").find((x) -> x.id is u.id)
          if user?
            if user.participate
              wishes = wishesFor(user)
              if wishes?
                inUsers.push("#{u.real_name or u.name} y ya pidió su :gift:")
              else
                inUsers.push(u.real_name or u.name)
            else
              outUsers.push(u.real_name or u.name)
          else
            notConfirmed.push(u.real_name or u.name)

        res.send "*Personas geniales que ya me confirmaron* :heart_eyes: :\n#{inUsers.join('\n')}\n\n" +
                 "*Aún no me confirman :unamused: *:\n#{notConfirmed.join('\n')}\n\n" +
                 "*No les interesa nada y quieren ver arder este mundo* :zap: :fire: :boom: :\n#{outUsers.join('\n')}"
      .catch((err) -> robot.emit("error", err))

  robot.respond /amigo secreto mis deseos$/i, (res) ->
    wishes = robot.brain.get("amigo-secreto:wishes") or []
    user = wishes.find((x) -> x.id is res.message.user.id)
    message = "No has deseado nada aún :disappointed:"
    if user?
      if user.wishes?
        myWishes = user.wishes.map((x, i) -> "#{i + 1}) #{x}").join("\n")
        message = "Tus deseos son:\n#{myWishes}"
    res.send(message)
