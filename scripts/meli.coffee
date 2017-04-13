# Commands:
#   publicar <asin> en <category_meli>
#   categoría de <url_meli>
#   donde meto <un/una> <nombre_del_producto> - predice categoría

module.exports = (robot) ->

  publicar = (res) ->
    key = process.env.KEY
    if (key?)
      # res.send "#{res.match[1]} #{res.match[2]} #{key}"
      data = JSON.stringify({
        asin: res.match[1],
        category: res.match[2],
        key: key
      })
      robot.http("http://productos.meloncargo.com/api/melis/publish")
        .header('Content-Type', 'application/json')
        .post(data) (err, response, body) ->
          robot.logger.debug('PUBLICAR: data-> ' + data + '\nerr->\t' + err + '\nstatusCode->\t' + response.statusCode + '\nbody->\t' + body)
          if err
            res.send "Hay algo mal aquí!"
            return
          if response.statusCode isnt 200
            res.send "Quokka me respondió con un error :cry:"
            return
          url = JSON.parse(body).url || 'No pude publicar ' + res.match[1] + ' en ' + res.match[2] + ' :sweat_smile:'
          res.send url

    else
      res.send "No se ingresó el token (KEY)"

  robot.hear /^publicar (.*) en (.*)/i, publicar
  robot.hear /^p (.*) (.*)/i, publicar

  categoria = (res) ->
    id = /MLC-(\d+)-/i.exec(res.match[1])
    if !id
      res.send("Me parece que " + res.match[1] + " no es una dirección meli válida")
      return
    mlc_id = "MLC#{id[1]}"
    robot.http("https://api.mercadolibre.com/items?ids=#{mlc_id}&attributes=category_id")
      .get() (err, response, body) ->
        robot.logger.debug('CATEGORÍA: mlc_id-> ' + mlc_id + '\nerr->\t' + err + '\nstatusCode->\t' + response.statusCode + '\nbody->\t' + body)
        if err
          res.send "Hay algo mal aquí!"
          return
        if response.statusCode isnt 200
          res.send "MeLi me respondió con un error :("
          return
        pbody = JSON.parse body
        robot.http("https://api.mercadolibre.com/categories/#{pbody[0].category_id}")
          .get() (err, response, body2) ->
            robot.logger.debug('CATEGORÍA: body-> ' + body + '\nerr->\t' + err + '\nstatusCode->\t' + response.statusCode + '\nbody2->\t' + body2)
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
        robot.logger.debug('DONDE METO: data-> ' + data + '\nerr->\t' + err + '\nstatusCode->\t' + response.statusCode + '\nbody->\t' + body)
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
