libxmljs = require 'libxmljs'

class RidRenderer
  constructor: (errorCallback) ->
    @errorCallback = errorCallback

  init: (str) ->
    elements = ['A', 'B', 'C', 'D', 'answer', 'answers', 'blank', 'correct',
                'explanation', 'interpretation', 'intro', 'level', 'list',
                'meaning', 'numbers', 'part5', 'part6', 'pattern', 'riiid',
                'text', 'type', 'voca', 'vocalist', 'word'].join('|')
    str = str.replace /<(blank|numbers)>/g, '<$1></$1>'
    str = str.replace new RegExp("<(\\/?)(#{elements})>", 'g'), '#r#$1$2#r#'
    str = str.replace /</g, '&lt;'
    str = str.replace />/g, '&gt;'
    str = str.replace /&/g, '&amp;'
    str = str.replace /"/g, '&quot;'
    str = str.replace /'/g, '&apos;'
    str = str.replace new RegExp("#r#(\\/?)(#{elements})#r#", 'g'), '<$1$2>'
    str

  render: (str) ->
    data = @init str
    doc = null
    try
      doc = libxmljs.parseXml(data)
    catch error
      @errorCallback('[rid] 미리보기 실패! 뭔가 잘못됐어요 :/', error)
      return ''

    html = libxmljs.Document()
    root = html.node('div')

    partList = doc.root().childNodes()
    for part in partList
      switch part.name()
        when 'part5' then root.addChild @parsePart5(html, part)
        when 'part6' then root.addChild @parsePart6(html, part)

    @errorCallback("[rid] 미리보기 성공!", null)
    str = root.toString()
    str = str.replace /&lt;/g, '<'
    str = str.replace /&gt;/g, '>'
    str = str.replace /&amp;/g, '&'
    str = str.replace /&quot;/g, '"'
    str = str.replace /&apos;/g, "'"
    str

  parsePart5: (html, node) ->
    root = libxmljs.Element(html, 'section')
    root.attr({class: 'part5'})

    children = node.childNodes()
    for child in children
      text = child.text().trim()
      switch child.name()
        when 'text' then @makeTextOfPart5 html, root, child
        when 'list' then @makeChoiceList html, root, child
        when 'level' then @makeLevel html, root, child
        when 'correct' then @makeCorrect html, root, child
        when 'pattern' then @makePattern html, root, child
        when 'interpretation' then @makeInterpretation html, root, child
        when 'explanation' then @makeExplanation html, root, child
        when 'vocalist' then @makeVocaList html, root, child
    root

  parsePart6: (html, node) ->
    root = libxmljs.Element(html, 'section')
    root.attr({class: 'part6'})

    children = node.childNodes()
    for child in children
      text = child.text().trim()
      switch child.name()
        when 'intro' then @makeIntroPart html, root, child
        when 'text' then @makeTextOfPart6 html, root, child
        when 'interpretation' then @makeInterpretation html, root, child
        when 'vocalist' then @makeVocaList html, root, child
        when 'answers' then @makeAnswers html, root, child
    root

  makeLevel: (html, parent, node) ->
    text = node.text().trim().replace(/\n/g, '<br/>')
    text = "<div class='level'>난이도: #{text}</div>"
    doc = libxmljs.parseHtml(text)
    root = doc.root()
    parent.addChild root

  makeCorrect : (html, parent, node) ->
    text = node.text().trim().replace(/\n/g, '<br/>')
    text = "<div class='correct'>정답: #{text}</div>"
    doc = libxmljs.parseHtml(text)
    root = doc.root()
    parent.addChild root

  makePattern : (html, parent, node) ->
    text = node.text().trim().replace(/\n/g, '<br/>')
    text = "<div class='pattern'>유형: #{text}</div>"
    doc = libxmljs.parseHtml(text)
    root = doc.root()
    parent.addChild root

  makeInterpretation : (html, parent, node) ->
    text = node.text().trim().replace(/\n/g, '<br/>')
    text = "<div class='interpretation'><h4>해석</h4><p>#{text}</p></div>"
    doc = libxmljs.parseHtml(text)
    root = doc.root()
    parent.addChild root

  makeExplanation: (html, parent, node) ->
    text = node.text().trim().replace(/\n/g, '<br/>')
    text = "<div class='explanation'><h4>해설</h4><p>#{text}</p></div>"
    doc = libxmljs.parseHtml(text)
    root = doc.root()
    parent.addChild root

  makeTextOfPart5: (html, parent, node) ->
    children = node.childNodes()
    if children.length == 0
      return

    root = libxmljs.Element(html, 'p').attr(class: 'part5text')
    for child in children
      text = child.text().trim()
      switch child.name()
        when 'text' then root.node('span', text)
        when 'blank' then root.node('span', ' ______ ').attr({class: 'blank'})
    parent.addChild root

  makeChoiceList: (html, parent, node) ->
    root = libxmljs.Element(html, 'ol').attr({class: 'choice', type: 'A'})
    children = node.childNodes()
    for child in children
      text = child.text().trim()
      switch child.name()
        when 'A' then root.node('li', text).attr({class: 'choice-a'})
        when 'B' then root.node('li', text).attr({class: 'choice-b'})
        when 'C' then root.node('li', text).attr({class: 'choice-c'})
        when 'D' then root.node('li', text).attr({class: 'choice-d'})
    parent.addChild root

  makeVocaList: (html, parent, node) ->
    root = libxmljs.Element(html, 'div').attr(class: 'vocalist')
    root.node('h4', '어휘')
    ul = root.node('ul')
    children = node.childNodes()
    for child in children
      if child.name() == 'voca'
        buff = ''
        for grandChild in child.childNodes()
          text = grandChild.text().trim()
          switch grandChild.name()
            when 'word' then buff = "#{text}: "
            when 'meaning' then buff += text
        ul.node('li', buff)
    parent.addChild root

  makeTextOfPart6: (html, parent, node) ->
    children = node.childNodes()
    if children.length == 0
      return

    root = libxmljs.Element(html, 'p').attr(class: 'part6text')
    for child in children
      switch child.name()
        when 'text' then @appendText html, root, child
        when 'blank' then root.node('span', ' ______ ').attr({class: 'blank'})
        when 'list' then @makeChoiceList html, root, child
    parent.addChild root

  appendText: (html, parent, node) ->
    text = node.text().trim().replace(/\n/g, '<br/>')
    text = "<span>#{text}</span>"
    doc = libxmljs.parseHtml(text)
    root = doc.root()
    parent.addChild root

  makeIntroPart: (html, parent, node) ->
    root = libxmljs.Element(html, 'div').attr(class: 'intro')
    children = node.childNodes()
    for child in children
      text = child.text()
      switch child.name()
        when 'text' then @appendText html, root, child
        when 'numbers' then root.node('span', ' x~y ').attr({class: 'numbers'})
        when 'type' then root.node('span', " #{text} ").attr({class: 'type'})
    parent.addChild root

  makeAnswers: (html, parent, node) ->
    root = libxmljs.Element(html, 'div').attr(class: 'answers')
    root.node('h3', '답 목록')
    children = node.childNodes()
    for child in children
      if child.name() == 'answer'
        @makeAnswer html, root, child
    parent.addChild root

  makeAnswer: (html, parent, node) ->
    root = libxmljs.Element(html, 'div').attr(class: 'answer')
    children = node.childNodes()
    root.node('hr')
    for child in children
      switch child.name()
        when 'level' then @makeLevel html, root, child
        when 'correct' then @makeCorrect html, root, child
        when 'pattern' then @makePattern html, root, child
        when 'explanation' then @makeExplanation html, root, child
    parent.addChild root

module.exports = RidRenderer
