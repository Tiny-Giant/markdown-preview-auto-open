{CompositeDisposable} = require 'atom'

module.exports = MarkdownPreviewAutoOpen =
  config:
    suffixes:
      type: 'array'
      default: ['markdown', 'md', 'mdown', 'mkd', 'mkdown']
      items:
        type: 'string'
    closePreviewWhenClosingFile:
      type: 'boolean'
      default: true

  activate: (state) ->
    process.nextTick =>
      if not (atom.packages.getLoadedPackage 'markdown-preview')
        console.log 'markdown-preview-auto-open: markdown-preview package not found'
        return

    atom.workspace.onDidOpen(@openPreview)
    atom.workspace.onDidStopChangingActivePaneItem(@switchPreview)

  switchPreview: (item) ->
    return unless item
    previewUrl = "markdown-preview://editor/#{item.id}"
    previewPane = atom.workspace.paneForURI(previewUrl)
    previewItem = previewPane?.itemForURI(previewUrl)
    if previewItem
      previewPane.activateItem(previewItem)

  openPreview: (event) ->
    return unless event?.uri and event?.item
    return if event.uri.startsWith('markdown-preview://')
    suffix = event.uri.match(/(\w*)$/)[1]
    return unless suffix in atom.config.get('markdown-preview-auto-open.suffixes')

    previewUrl = "markdown-preview://editor/#{event.item.id}"
    previewPane = atom.workspace.paneForURI(previewUrl)

    if not previewPane
      workspaceView = atom.views.getView(atom.workspace)
      atom.commands.dispatch workspaceView, 'markdown-preview:toggle'

    if atom.config.get('markdown-preview-opener.closePreviewWhenClosingFile')
      if event.item.onDidDestroy
        event.item.onDidDestroy ->
          for pane in atom.workspace.getPanes()
            for item in pane.items when item.getURI() is "markdown-preview://#{event.uri}"
              pane.destroyItem(item)
              break
