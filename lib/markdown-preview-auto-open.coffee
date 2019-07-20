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
    previewItem = previewPane && previewPane.itemForURI(previewUrl)
    if not previewPane
      workspaceView = event.item.component.element
      atom.commands.dispatch workspaceView, 'markdown-preview:toggle'
      process.nextTick =>
        previewPane = atom.workspace.paneForURI(previewUrl)
        previewItem = previewPane && previewPane.itemForURI(previewUrl)

    if atom.config.get('markdown-preview-auto-open.closePreviewWhenClosingFile')
      if event.item.onDidDestroy
        event.item.onDidDestroy ->
          previewPane.destroyItem(previewItem)

    # Focus original pane after opening preview
    process.nextTick =>
      pane = atom.workspace.paneForURI(event.uri)
      if pane
        pane.activate()
