# Commands:
#   bug -> entrega una excusa, no es mi culpa!
#   sfw <palabra> -> Busca un gif animado del texto indicado

# Comentar Shell para probar "else" en consola
allowed = ['prueba', 'socios', 'G0KAB6CRK', 'Shell']

bizarres = [
  "wtflolporn.tumblr.com",
  "awkwardjapaneseporngifs.tumblr.com",
]

bizarre_talk = [
  'Ya, me fui a la chucha nuevamente :scream:',
  'Me puse extremo pa mis cosas :see_no_evil:',
  'Esto es lo más rancio que pillé :confounded:' ,
  'Traido para ud directamente de la deep web :computer:',
  'Ups, no quería mostrarte esto :smiling_imp:'
]

module.exports = (robot) ->
  tumblr = require('tumblrbot')(robot)

  robot.hear /^nsfw ?(.*)$/i, (res) ->
    if(allowed.indexOf(res.envelope.room) > -1)
      param = res.match[1]
      if param == 'bomb'
        for i in [1..5]
          nsfw(res)
      else
        nsfw(res)
    else
      safe(res)

  nsfw = (res) ->
    if(Math.random() > 0.1)
      res.http('http://titsnarse.co.uk/random_json.php')
        .get() (error, response, body) ->
          if body == null
            cat(res)
          else
            res.send 'http://titsnarse.co.uk'+JSON.parse(body).src
    else
      tumblr.photos(res.random bizarres).random (post) ->
        console.log post.photos
        if body == null
          cat(res)
        else
          res.send res.random(bizarre_talk) + ' ' + post.photos[0].original_size.url
  safe = (res) ->
    robot.logger.info('Trying to get NSFW from: [' + res.envelope.room + ']')
    res.send 'En Meloncargo trabajamos seguros'

  cat = (res) ->
    res.send 'No me responde el servidor. En su reemplazo disfruta un gatito :cat2: http://thecatapi.com/api/images/get?format=src'

  robot.hear /^sfw ?(.*)$/i, (res) ->
    param = res.match[1]
    url = 'http://api.giphy.com/v1/gifs/'
    if (param)
      res.send "Déjame buscarte un memazo de " + param
      res.http(url + 'search?api_key=dc6zaTOxFJmzC&limit=100&sort=relevant&q=' + param)
        .get() (error, response, body) ->
          results = JSON.parse(body).data
          if results.length > 0
            rand = results[Math.floor(Math.random() * results.length)]
            res.send rand.images.original.url
          else
            res.send "Sorry, pero nadie conoce " + param + ' :nerd_face:'

    else
      res.send "Déjame buscarte un memazo random"
      res.http(url + 'random?api_key=dc6zaTOxFJmzC')
        .get() (error, response, body) ->
          res.send JSON.parse(body).data.image_url

  robot.hear /^bug/i, (res) ->
#    res.http('https://api.githunt.io/programmingexcuses')
#      .get() (error, _, body) ->
#        res.send body
    res.send "Me importa un carajo"
