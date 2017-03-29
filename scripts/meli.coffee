# Commands:
#   publicar <asin> en <category_meli>
#   categoría de <url_meli>
#   donde meto <un/una> <nombre_del_producto> - predice categoría

module.exports = (robot) ->

  robot.hear /^publicar (.*) en (.*)/i, (res) ->
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
        .post(data) (err, _, body) ->
          if err
            res.send "Hay algo mal aquí!"
            return
          if res.statusCode isnt 200
            res.send "Quokka me respondió con un error :("
            return
          pbody = JSON.parse body
          res.send pbody.url

    else
      res.send "No se ingresó el token (KEY)"

  robot.hear /^categor[í|i]a de (.*)/i, (res) ->
    mlc_id = /MLC-(\d+)-/i.exec(res.match[1])[1]
    mlc_id = "MLC#{mlc_id}"
    robot.http("https://api.mercadolibre.com/items?ids=#{mlc_id}&attributes=category_id")
      .get() (err, _, body) ->
        if err
          res.send "Hay algo mal aquí!"
          return
        if res.statusCode isnt 200
          res.send "MeLi me respondió con un error :("
          return
        pbody = JSON.parse body
        robot.http("https://api.mercadolibre.com/categories/#{pbody[0].category_id}")
          .get() (err, _, body2) ->
            if err
              res.send "Hay algo mal aquí!"
              return
            if res.statusCode isnt 200
              res.send "MeLi me respondió con un error :("
              return
            pbody2 = JSON.parse body2
            tree = pbody2.path_from_root.map( (x) -> x.name ).join(" > ")
            res.send "#{pbody2.id} #{tree}"

  robot.hear /^donde meto (un|una|unos|unas) (.*)/i, (res) ->
    data = JSON.stringify([{
      title: res.match.pop()
    }])

    robot.http("https://api.mercadolibre.com/sites/MLC/category_predictor/predict")
      .header('Content-Type', 'application/json')
      .post(data) (err, _, body) ->
        if err
          res.send "Hay algo mal aquí!"
          return
        if res.statusCode isnt 200
          res.send "MeLi me respondió con un error :("
          return
        pbody = JSON.parse(body)[0]
        tree = pbody.path_from_root.map( (x) -> x.name ).join(" > ")
        if(Math.random() < 0.1)
          res.send "Mételo por: #{pbody.id} #{tree}"
        else
          res.send "#{pbody.id} #{tree}"
