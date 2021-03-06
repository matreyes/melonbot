# Commands:
#   publicar <asin> en <category_meli> - (Ya no funciona) Publica un producto de amazon en Mercado Libre
#   categoría de <url_meli> - Retorna categoría para una url de un producto Mercado Libre
#   donde meto <un/una> <nombre_del_producto> - Predice una categoría basado en el texto que se le entrega

# taken from quokka (config/initializers/variables.rb)
restricted_categories = [
  'MLC1055',
  'MLC1271',
  'MLC1247',
  'MLC175504',
  'MLC1259',
  'MLC8163',
  'MLC174669',
  'MLC1266',
  'MLC174672',
  'MLC174813',
  'MLC174675',
  'MLC174676',
  'MLC174671',
  'MLC7729',
  'MLC174678',
  'MLC174672',
  'MLC178731',
  'MLC174816',
  'MLC174817',
  'MLC44117',
  'MLC29890',
  'MLC1251',
  'MLC1249',
  'MLC1252'
]

module.exports = (robot) ->
  hubotEnv = process.env.HUBOT_ENV
  robot.logger.debug('ENVIRONMENT IS: ' + hubotEnv)

  publicar = (res) ->
    key = process.env.KEY

    if (key?)
      # res.send "#{res.match[1]} #{res.match[2]} #{key}"
      data = JSON.stringify({
        asin: res.match[2],
        category: res.match[4],
        key: key
      })
      console.log(data)
      res.send 'Publicando ' + res.match[2] + ' en ' + res.match[4] + ' ...'
      publUrl = if hubotEnv is 'production' then 'http://productos.meloncargo.com' else 'http://localhost:3000'
      robot.http(publUrl + "/api/melis/publish")
        .header('Content-Type', 'application/json')
        .post(data) (err, response, body) ->
          robot.logger.info('PUBLICAR: \n\tdata-> ' + data + '\n\terr->' + err)
          if err
            message = "Hay algo mal aquí!"
          else if response.statusCode >= 500
            message = "Quokka me respondió con un error :cry:"
          else
            json = JSON.parse(body)
            if json.url
              if json.created_at
                message = "Ya publiqué #{json.url} antes. Recuerdo que fue hace #{json.created_at} atrás."
              else
                message = json.url
            else if json.error
              message = json.error
            else
              message = body
          res.send process_publicar_result(message)
    else
      res.send "No se ingresó el token (KEY)"

  process_publicar_result = (message) ->
    robot.logger.info(message)
    switch true
      when /AWS\.InvalidParameterValue/.test(message) # p 12345 MLC172569
        return "No encontré el ítem :angry:";
      when /AWS\.ECommerceService\.ItemNotAccessible/.test(message) # p B0081AWTZA MLC159317
        return "Amazon informa que este item está bloqueado. Prueba con otro :facepunch:";
      when /AWS\.InvalidAssociate/.test(message) # p B0081AWTZA MLC159317
        return "*Amazon nos bloqueó*. Nada que hacer más que llorar en un rincón :crying_cat_face:";
      when /item\.category_id\.invalid/.test(message) # p B00HZI5XBG MLC172569
        return "No encontré la categoría :angry:";
      when /item\.buying_mode\.invalid/.test(message) # p B007W6X2M8 en MLC32443
        if /only supports listing modes/.test(message)
          category = message.match(/Category (.+) only/)[1]
          modes = message.match(/modes: (.+)$/)[1]
          return "La categoría #{category} solo soporta publicaciones de tipo: #{modes} :hankey:";
        else
          reason = message.match(/.+\)\s(.*)$/)[1]
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

  robot.hear /^(publica[r]?|p)\s+(\w+)(\s+en)?\s+(\w+)$/i, publicar

  categoria = (res) ->
    id = /MLC-(\d+)-/i.exec(res.match[3])
    if !id
      res.send("Me parece que " + res.match[3] + " no es una dirección meli válida")
      return
    mlc_id = "MLC#{id[1]}"
    robot.http("https://api.mercadolibre.com/items?ids=#{mlc_id}&attributes=category_id")
      .get() (err, response, body) ->
        robot.logger.info('CATEGORÍA: \n\tmlc_id-> ' + mlc_id + '\n\terr->' + err + '\n\tbody->' + body)
        if err
          res.send "Hay algo mal aquí!"
          return
        if response.statusCode isnt 200
          res.send "MeLi me respondió con un error :("
          return
        if body == '[]'
          res.send "Categoría #{mlc_id} no existe"
          return
        pbody = JSON.parse body
        robot.http("https://api.mercadolibre.com/categories/#{pbody[0].category_id}")
          .get() (err, response, body2) ->
            robot.logger.info('CATEGORÍA: \n\tbody-> ' + body + '\n\terr->' + err + '\n\tbody2->' + body2)
            if err
              res.send "Hay algo mal aquí!"
              return
            if response.statusCode isnt 200
              res.send "MeLi me respondió con un error :("
              return
            pbody2 = JSON.parse body2
            tree = pbody2.path_from_root.map( (x) -> x.name ).join(" > ")
            res.send "#{pbody2.id} #{tree}"

  robot.hear /^(categor[í|i]a|c)(\s+de)?\s+(\S+)/i, categoria

  dondeMeto = (res) ->
    title = res.match[3]
    data = JSON.stringify([{ title: title }])
    robot.http("https://api.mercadolibre.com/sites/MLC/category_predictor/predict")
      .header('Content-Type', 'application/json')
      .post(data) (err, response, body) ->
        robot.logger.info('DONDE METO: \n\tdata-> ' + data + '\n\terr->' + err + '\n\tbody->' + body)
        if err
          res.send "Hay algo mal aquí!"
          return
        if response.statusCode isnt 200
          res.send "MeLi me respondió con un error :cry:"
          return
        pbody = JSON.parse(body)[0]
        tree = pbody.path_from_root.map( (x) -> x.name ).join(" > ")
        aditional = ''
        pre = ''
        mark = ''
        restriction = is_restricted(pbody.path_from_root)
        if restriction != undefined
          pre = ":bangbang: *Te recuerdo que #{title} pertenece a '#{restriction}', una de nuestras categorías restringidas*\n"
        # perc = Math.round(pbody.prediction_probability * 100)
        # chances = "(#{perc}% de probabilidad de acierto)"
        # mark = ':white_check_mark:'
        # if perc < 40 && perc >= 20
        #   mark = ":warning:"
        #   aditional = "\n ¿quizás se pueda refinar la búsqueda de #{title}? #{chances}"
        # else if perc < 20
        #   mark = ":exclamation:"
        #   aditional = "\n Quizás una categoría adecuada para #{title} no puede ser encontrada #{chances}"
        res.send "#{pre}#{mark} #{pbody.id} #{tree} #{aditional}"

  is_restricted = (paths) ->
    for i in paths
      if restricted_categories.indexOf(i.id) >= 0
        return i.name
    return undefined

  robot.hear /^(donde meto|dm)\s*(un|una|unos|unas)?\s+(.+)/i, dondeMeto
