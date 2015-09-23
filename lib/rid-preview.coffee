url = require 'url'
fs = require 'fs-plus'

RidPreviewView = null
{CompositeDisposable} = require 'atom'

createRidPreviewView = (state) ->
  RidPreviewView ?= require './rid-preview-view'
  new RidPreviewView(state)

isRidPreviewView = (object) ->
  RidPreviewView ?= require './rid-preview-view'
  object instanceof RidPreviewView

atom.deserializers.add
  name: 'RidPreviewView'
  deserialize: (state) ->
    if state.editorId or fs.isFileSync(state.filePath)
      createRidPreviewView(state)

module.exports =
  config:
    openPreviewInSplitPane:
      type: 'boolean'
      default: true
    grammars:
      type: 'array'
      default: [
        'text.rid'
      ]
  ridPreviewView: null

  activate: (state) ->
    atom.commands.add 'atom-workspace',
      'rid-preview:toggle': => @toggle()

    previewFile = @previewFile.bind(this)
    atom.commands.add '.tree-view .file .name[data-name$=\\.riiid]',
      'rid-preview:preview-file', previewFile
    atom.commands.add '.tree-view .file .name[data-name$=\\.rid]',
      'rid-preview:preview-file', previewFile

    atom.workspace.addOpener (uriToOpen) ->
      try
        {protocol, host, pathname} = url.parse(uriToOpen)
      catch error
        return

      return unless protocol is 'rid-preview:'

      try
        pathname = decodeURI(pathname) if pathname
      catch error
        return

      if host is 'editor'
        createRidPreviewView(editorId: pathname.substring(1))
      else
        createRidPreviewView(filePath: pathname)

  toggle: ->
    if isRidPreviewView(atom.workspace.getActivePaneItem())
      atom.workspace.destroyActivePaneItem()
      return

    editor = atom.workspace.getActiveTextEditor()
    return unless editor?

    grammars = atom.config.get('rid-preview.grammars') ? []
    return unless editor.getGrammar().scopeName in grammars

    @addPreviewForEditor(editor) unless @removePreviewForEditor(editor)

  uriForEditor: (editor) ->
    "rid-preview://editor/#{editor.id}"

  removePreviewForEditor: (editor) ->
    uri = @uriForEditor(editor)
    previewPane = atom.workspace.paneForURI(uri)
    if previewPane?
      previewPane.destroyItem(previewPane.itemForURI(uri))
      true
    else
      false

  addPreviewForEditor: (editor) ->
    uri = @uriForEditor(editor)
    previousActivePane = atom.workspace.getActivePane()
    options =
      searchAllPanes: true
    if atom.config.get('rid-preview.openPreviewInSplitPane')
      options.split = 'right'
    atom.workspace.open(uri, options).then (ridPreviewView) ->
      if isRidPreviewView(ridPreviewView)
        previousActivePane.activate()

  previewFile: ({target}) ->
    filePath = target.dataset.path
    return unless filePath

    for editor in atom.workspace.getTextEditors() when editor.getPath() is filePath
      @addPreviewForEditor(editor)
      return

    atom.workspace.open "rid-preview://#{encodeURI(filePath)}",
      searchAllPanes: true
