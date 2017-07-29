// Description:
//   Obtiene indicadores económicos para Chile
//
// Dependencies:
//   none
//
// Configuration:
//   None
//
// Commands:
//   melonbot valor help
//   melonbot valor dolar|usd
//   melonbot valor bitcoin
//   melonbot valor uf
//   melonbot valor euro
//   melonbot valor ipc
//   melonbot valor utm
//
// Author:
//   @jorgeepunan

// process.env.API_URL ||= 'http://mindicador.cl/api' // old, slow and shitty
// const API_URL = process.env.API_URL || 'http://indicadoresdeldia.cl/webservice/indicadores.json'
"use strict";

const API_URL = process.env.API_URL || 'http://mindicador.cl/api'
const BIT_API_URL = process.env.BIT_API_URL || 'https://blockchain.info/es/ticker'
const mensajes = [
  'Aunque te esfuerces, seguirás siendo pobre. :poop:',
  'Los políticos ganan más que tú y más encima nos roban. Y no pueden irse presos. ¡Ánimo! :monkey:',
  'La economía seguirá mal para ti, pero no para tu AFP. :moneybag:',
  'Algún día saldrás de la clase media. Partiste a jugarte un LOTO. :alien:',
  'Todos los días suben los precios, y no tu sueldo. :money_with_wings:'
]

const numberWithCommas = number =>
  number.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.')

const numberSplitDecimal = number => {
  const d = Math.pow(10, 2)
  return (parseInt(number * d, 10) / d).toFixed(number)
}

module.exports = robot => {
  robot.respond(/valor (\w+)/i, res => {
    let uri
    const indicador = res.match[1].toLowerCase()
    const helpMessage = 'Mis comandos son:\n\n * `valor dolar|usd`\n * `valor euro|eur`\n * `valor bitcoin|btc`\n * `valor uf`\n * `valor utm`\n * `valor ipc`\n'
    if (indicador === 'help' || !indicador) {
      res.send(helpMessage)
      return false
    }
    const indicadors = ['uf', 'dolar', 'usd', 'euro', 'eur', 'ipc', 'utm']
    if (indicadors.includes(indicador)) {
      uri = API_URL
    } else if (['bitcoin', 'btc'].includes(indicador)) {
      uri = BIT_API_URL
    }
    res.robot.http(uri).get()((err, response, body) => {
      if (err) {
        robot.emit('error', err, response)
        res.send(`Ocurrio un error: ${err.message}`)
        return
      }
      response.setEncoding('utf-8')
      let data = JSON.parse(body)
      let date = ` (${data.fecha})`
      if (indicador === 'uf') {
        data = data.uf.valor
      } else if (['dolar', 'usd'].includes(indicador)) {
        data = data.dolar.valor
      } else if (['euro', 'eur'].includes(indicador)) {
        data = data.euro.valor
      } else if (indicador === 'ipc') {
        data = `${data.ipc.valor}%`
      } else if (indicador === 'utm') {
        data = data.utm.valor
      } else if (['bitcoin', 'btc'].includes(indicador)) {
        date = ''
        const flatNumber = data.CLP.last.toString().split('.')[0]
        data = `$${numberWithCommas(flatNumber)}`
      } else {
        data = '`valor help` para ayuda.'
      }
      if (data !== null && typeof data !== 'object') {
        data = data.toString().split(',', 1)
        const mensaje = res.random(mensajes)
        res.send(`${indicador.toUpperCase()}: ${data}${date}. ${mensaje}`)
      } else {
        res.send(helpMessage)
      }
    })
  })
}
