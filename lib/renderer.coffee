RidRenderer = require './rid-renderer'

exports.toDOMFragment = (text = '', filePath, grammar, callback) ->
  render text, filePath, (error, html) ->
    return callback(error) if error?

    notiCb = (message, error) ->
      noti?.dismiss
      if error != null
        atom.notifications.addError message,
          detail: error
          dismissable: false
      else
        atom.notifications.addSuccess message,
          dismissable: false

    template = document.createElement('template')
    html = new RidRenderer(notiCb).render(html, {noblanks: true})
    template.innerHTML = html
    domFragment = template.content.cloneNode(true)

    callback(null, domFragment)

render = (text, filePath, callback) ->
  callback(null, text)
