// Description:
//   melonbot muestra saldo tarjeta BIP! ázì nòmá
//
// Dependencies:
//   None
//
// Configuration:
//   None
//
// Commands:
//   melonbot bip <numero>
//
// Notes:
//   API prestada de alguien más q no lo sabe (aún)
//
// Author:
//   @jorgeepunan

module.exports = function(robot) {

  return robot.respond(/bip (\w+)/i, function(msg) {

    var indicador = msg.match[1];
    msg.send('La consulta va en la micro... espere harto... :clock5:');

    if (isNaN(indicador)) {
      msg.send('El identificador de tu BIP! son sólo números.');
    } else {
      var url = `http://bip-servicio.herokuapp.com/api/v1/solicitudes.json?bip=${indicador}`;

      return msg.http(url).get()(function(err, res, body) {
        if (err) {
          msg.send('Algo pasó, intente nuevamente.');
        }
        if (body.indexOf('<') > -1) {
          msg.send('Error, intente con otro número.');
        } else {
          res.setEncoding('utf-8');
          var data = JSON.parse(body);
          if (data) {
            return (() => {
              var result = [];
              for (var prop in data) {
                result.push( msg.send(`${prop} => ${data[prop]}`) );
              }
              return result;
            })();
          } else {
            msg.send('Error!');
          }
        }
      });
    }

  });

};
