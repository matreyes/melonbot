// Description:
//   Imprime una url a un gif de table flipping
//
// Dependencies:
//   None
//
// Configuration:
//   None
//
// Commands:
//   melonbot enojo|rabia|furia
//
// Author:
//   @hectorpalmatellez

module.exports = function(robot) {
  robot.hear(/enoj[ao]|rabia|furi[ao]/i, function(msg) {
    var url = 'http://tableflipper.com/json';
    msg.robot.http(url).get()(function(err, res, body) {
      var data = JSON.parse(body);
      msg.send(data.gif);
    });
  });
};
