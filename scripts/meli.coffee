# Commands:
#   publicar <asin> en <category_meli>
#   categoría de <url_meli>
#   donde meto <un/una> <nombre_del_producto> - predice categoría

module.exports = (robot) ->

  publicar = (res) ->
    key = process.env.KEY
    hubotEnv = process.env.HUBOT_ENV
    if (key?)
      # res.send "#{res.match[1]} #{res.match[2]} #{key}"
      data = JSON.stringify({
        asin: res.match[1],
        category: res.match[2],
        key: key
      })
      res.send 'Publicando ' + res.match[1] + ' en ' + res.match[2] + ' ...'
      publUrl = if hubotEnv is 'production' then 'http://productos.meloncargo.com' else 'http://localhost:3000'
      robot.http(publUrl + "/api/melis/publish")
        .header('Content-Type', 'application/json')
        .post(data) (err, response, body) ->
          robot.logger.info('PUBLICAR: \n\tdata-> ' + data + '\n\terr->' + err + '\n\tstatusCode->' + response.statusCode)
          if err
            message = "Hay algo mal aquí!"
          else if response.statusCode >= 500
            message = "Quokka me respondió con un error :cry:"
          else
            message = JSON.parse(body).url or 'No pude publicar ' + res.match[1] + ' en ' + res.match[2] + ' :sweat_smile:'
          res.send process_publicar_result(message)
    else
      res.send "No se ingresó el token (KEY)"

  process_publicar_result = (message) ->
    robot.logger.info(message)
    switch true
      when /AWS\.InvalidParameterValue/.test(message) # p 12345 MLC172569
        return "No encontré el ítem :angry:";
      when /item\.category_id\.invalid/.test(message) # p B00HZI5XBG MLC172569
        return "No encontré la categoría :angry:";
      when /item\.buying_mode\.invalid/.test(message)
        reason = message.match(/: \[(.*)\]\./)[1];
        return "Tu item no se permite en la categoría por: #{reason} :face_with_rolling_eyes:";
      when /item\.attributes\.missing_required/.test(message) # P B00FGKXJL6 MLC31452
        return "No pude publicar, ya que la categoría requiere atributos adicionales (ej: talla, color, etc.) que no me es posible entregárselos a meli.\nMejor suerte con el próximo producto :sweat_smile:";
      when /No available price/.test(message) # p B01MFCTRZM MLC1699
        return "No pude publicar, ya que amazon no me entregó un precio de este producto.\nPuede deberse a que no hayan nuevos disponibles, solo usados o reaciondicionados :money_mouth_face:"
      when /internal_error/.test(message)
        return ":construction_worker: ahora mismo Mercado Libre está con problemas. Inténtalo nuevamente más tarde."
      when /You are submitting requests too quickly/.test(message)
        return "Amazon me reclama que estoy haciendo muchas llamadas. Espera unos segundos y vuelve a intentar :snail:"
      when /No shipping weight/.test(message)
        return "No hay información sobre el peso de envío para el producto que trataste de publicar :weight_lifter:"
      when /Already published/.test(message)
        return "Este producto ya fue publicado :sunglasses:"
      when /Product is not present/.test(message)
        return "Producto no está presente en Quokka :mag_right:"
      when /Item not available/.test(message)
        return "Item no se encuentra disponible :package:"
      when /No category/.test(message)
        return "No se pudo asignar una categoría al producto :hash:"
      when /Product disabled/.test(message)
        return "Producto se encuentra desactivado para publicar :cop:"
      else
        return message

  robot.hear /^publicar (\w*) en (\w*)$/i, publicar
  robot.hear /^p (\w*) (\w*)$/i, publicar
  robot.hear /^p (\w*) en (\w*)$/i, publicar

  categoria = (res) ->
    id = /MLC-(\d+)-/i.exec(res.match[1])
    if !id
      res.send("Me parece que " + res.match[1] + " no es una dirección meli válida")
      return
    mlc_id = "MLC#{id[1]}"
    robot.http("https://api.mercadolibre.com/items?ids=#{mlc_id}&attributes=category_id")
      .get() (err, response, body) ->
        robot.logger.info('CATEGORÍA: \n\tmlc_id-> ' + mlc_id + '\n\terr->' + err + '\n\tstatusCode->' + response.statusCode + '\n\tbody->' + body)
        if err
          res.send "Hay algo mal aquí!"
          return
        if response.statusCode isnt 200
          res.send "MeLi me respondió con un error :("
          return
        pbody = JSON.parse body
        robot.http("https://api.mercadolibre.com/categories/#{pbody[0].category_id}")
          .get() (err, response, body2) ->
            robot.logger.info('CATEGORÍA: \n\tbody-> ' + body + '\n\terr->' + err + '\n\tstatusCode->' + response.statusCode + '\n\tbody2->' + body2)
            if err
              res.send "Hay algo mal aquí!"
              return
            if response.statusCode isnt 200
              res.send "MeLi me respondió con un error :("
              return
            pbody2 = JSON.parse body2
            tree = pbody2.path_from_root.map( (x) -> x.name ).join(" > ")
            res.send "#{pbody2.id} #{tree}"

  robot.hear /^categor[í|i]a de (.*)/i, categoria
  robot.hear /^c (.*)/i, categoria

  dondeMeto = (res) ->
    data = JSON.stringify([{
      title: res.match.pop()
    }])

    robot.http("https://api.mercadolibre.com/sites/MLC/category_predictor/predict")
      .header('Content-Type', 'application/json')
      .post(data) (err, response, body) ->
        robot.logger.info('DONDE METO: \n\tdata-> ' + data + '\n\terr->' + err + '\n\tstatusCode->' + response.statusCode + '\n\tbody->' + body)
        if err
          res.send "Hay algo mal aquí!"
          return
        if response.statusCode isnt 200
          res.send "MeLi me respondió con un error :cry:"
          return
        pbody = JSON.parse(body)[0]
        tree = pbody.path_from_root.map( (x) -> x.name ).join(" > ")
        if(Math.random() < 0.1)
          res.send "Mételo por: #{pbody.id} #{tree}"
        else
          res.send "#{pbody.id} #{tree}"

  robot.hear /^donde meto (un|una|unos|unas) (.*)/i, dondeMeto
  robot.hear /^dm (.*)/i, dondeMeto
