# Commands:
#   bug -> entrega una excusa, no es mi culpa!
#   nsfw -> Cuando algo no es seguro para trabajar, no es seguro para trabajar

module.exports = (robot) ->

  robot.hear /nsfw/i, (res) ->
    if(res.envelope.room=="prueba" || res.envelope.room=="socios")
      res.http('http://titsnarse.co.uk/random_json.php')
        .get() (error, response, body) ->
          res.send 'http://titsnarse.co.uk'+JSON.parse(body).src
    else
      res.send 'En Meloncargo trabajamos seguros'

  robot.hear /bug/i, (res) ->
    res.http('https://api.githunt.io/programmingexcuses')
      .get() (error, _, body) ->
        res.send body
