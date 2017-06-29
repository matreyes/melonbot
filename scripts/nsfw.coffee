# Commands:
#   bug -> entrega una excusa, no es mi culpa!
#   nsfw -> Cuando algo no es seguro para trabajar, no es seguro para trabajar

# Comentar Shell para probar "else" en consola
allowed = ['prueba', 'socios', 'G0KAB6CRK', 'Shell']

bizarres = [
  "wtflolporn.tumblr.com",
  "awkwardjapaneseporngifs.tumblr.com",
]

module.exports = (robot) ->
  tumblr = require('tumblrbot')(robot)

  robot.hear /^nsfw/i, (res) ->
    if(allowed.indexOf(res.envelope.room) > -1)
      res.http('http://titsnarse.co.uk/random_json.php')
        .get() (error, response, body) ->
          res.send 'http://titsnarse.co.uk'+JSON.parse(body).src
    else
      safe(res)

  robot.hear /^bizarre/i, (res) ->
    if(allowed.indexOf(res.envelope.room) > -1)
      blog = res.random bizarres
      tumblr.photos(blog).random (post) ->
        res.send post.photos[0].original_size.url
    else
      safe(res)

  safe = (res) ->
    robot.logger.info('Trying to get NSFW from: [' + res.envelope.room + ']')
    res.send 'En Meloncargo trabajamos seguros'

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
