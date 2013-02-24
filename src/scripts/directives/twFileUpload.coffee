###global define###

define ['libs/angular', 'directives/directives', 'libs/text!directives/templates/twFileUpload.html', 'jquery', 'jquery.fileupload'], (angular, directives, template, $) ->
  'use strict'

  directives.directive 'twFileUpload', [ '$timeout', ($timeout) ->
    link = (scope, element, attrs) ->

      #scope.uploading      = false
      scope.uploadingFiles = {}
      scope.disabled = attrs.disabled? and attrs.disabled
      scope.textDisabled = if attrs.textDisabled? then attrs.textDisabled else 'disabled'

      initializeFileUpload = (container, options) ->
        return if scope.disabled

        unless container?.jquery? and container.length is 1
          console.error 'The container has to be a jQuery-Object with one element selected.', container
          return false

        options = $.extend
          url                   : null # required
          dropZone              : null
          textZerobytes         : '0 Byte große Datei!'
          genericErrorMessage   : 'Fehler beim Upload'
          rootNodeName          : 'attachment'
          mapFields             : 'id,type,title,size,mimeType,link'
        , options

        # get jquery-object of given selector
        options.dropZone = if options.dropZone then $(options.dropZone) else null

        # *** call jquery fileupload plugin ***
        container.find('#fileinput').fileupload
          dataType  : 'text/plain'
          url       : options.url
          dropZone  : if typeof options.dropZone is 'string' then $(options.dropZone) else options.dropZone
          #converters: # Rest of the world
          #  'html iframexml'  : (htmlEncodedXml) -> $.parseXML($('<div/>').html(htmlEncodedXml).text())
          #  # IE
          #  'iframe iframexml': (iframe) -> $.parseXML(iframe.find('body').text())

          start: (event) ->
            console.log 'Uploading starting...'
            if options.start? and $.isFunction options.start
              options.start.apply scope, arguments

          add: (event, data) =>
            console.log 'Uploading adding...', data
            file = data.files[0]
            # IE (tested w/ 8) does not support size
            if typeof (file.size) isnt 'undefined' and not file.size
              event.preventDefault()
              scope.uploadingFiles[file.name] = progress: 0, errMsg: options.textZerobytes
              scope.$apply()
              container.find('.uploadArea').effect 'highlight', color: '#FF7575', 500
            else
              #scope.uploading    = true
              scope.uploadingFiles[file.name] = progress: 0, errMsg: ''
              scope.$apply()
              # sending data to server
              data.submit()

          send: (event, data) =>
            console.log 'Uploading sending...', data
            if options.send? and $.isFunction options.send
              options.send.apply scope, arguments

          progress: (event, data) =>
            file = data.files[0]
            progress = parseInt(data.loaded / data.total * 100, 10)
            console.log "Uploading in progress: #{progress}% - #{data.loaded}/#{data.total} Bytes transferred"
            scope.uploadingFiles[file.name]?.progress = progress
            scope.$apply()

          done: (event, data) =>
            file = data.files[0]
            console.log "Uploading finished"
            scope.uploadingFiles[file.name].progress = 100
            scope.$apply()

            # NOTE: Because of the IE workaround, in this special case, the result in data.result is an xml document.
            # Transforms the xml into an plain object.
            xmlData = $(data.result).find(options.rootNodeName)
            modelData = {}
            for field in options.mapFields.split(',')
              modelData[field] = xmlData.find('>'+field).text()

            #unless $.isFunction options.done
            #  console.warn 'Configuration error: specify a done callback for upload!'

            # add file to model
            #if localModel
            #  scope.localModel.push modelData
            scope.$apply()
            progressEl = container.find(".progress").filter('[data-file-id="' + file.name + '"]')
            resetUploadArea progressEl, file.name

            # call own doneFn ???
            #options.done.call @, modelData, file
            scope.done?(data: modelData)

          fail: (event, data) =>
            file = data.files[0]
            console.warn "Uploading failed. FAILED!"

            message = if data.jqXHR?.responseText? then data.jqXHR.responseText
            console.log message

            scope.uploadingFiles[file.name].errMsg = message or genericErrorMessage
            scope.$apply()

            resetUploadArea '', file.name

      resetUploadArea = (progEl, fileName) ->
        # fade out progress bars / use css3 transitions instead?!
        errMsg = scope.uploadingFiles[fileName].errMsg
        if not errMsg
          if progEl.length
            $timeout ->
              progEl.fadeOut 500, => # TODO set global fade-speed like this: App.Settings.FadeContentSpeed
                progEl.remove()
                delete scope.uploadingFiles[fileName]
                #scope.uploading = not $.isEmptyObject scope.uploadingFiles
                scope.$apply()
            , 1000
          else
            delete scope.uploadingFiles[fileName]
            #scope.uploading = not $.isEmptyObject scope.uploadingFiles
            scope.$apply()
      #scope.uploading = false

      scope.onClickFileDialog = ->
        element.find('#fileinput').trigger 'click'

      # init fileupload plugin
      scope.$watch "isReady", (isReady) ->
        return unless isReady

        initializeFileUpload element,
          url         : scope.url
          dropZone    : attrs.dropzone
          rootNodeName: attrs.rootNodeName
          mapFields   : attrs.mapFields


    link      : link
    restrict  : "E"
    replace   : true
    transclude: false
    scope     :
      isReady   : '=waitfor'
      localModel: '=model'
      url       : '@url'
      done      : '&'
    template  : template
  ]
