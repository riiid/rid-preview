exports.toDOMFragment = (text='', filePath, grammar, callback) ->
  render text, filePath, (error, html) ->
    return callback(error) if error?

    template = document.createElement('template')
    console.log html
    template.innerHTML = html
    domFragment = template.content.cloneNode(true)
    callback(null, domFragment)

render = (text, filePath, callback) ->
  callback(null, text)
