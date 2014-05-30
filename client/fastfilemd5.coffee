@fastFileMd5 = (file,cb) ->
  # read in chunks of 2MB
  # append array buffer
  # compute hash
  loadNext = ->
    fileReader = new FileReader()
    fileReader.onload = frOnload
    fileReader.onerror = frOnerror
    start = currentChunk * chunkSize
    end = (if ((start + chunkSize) >= file.size) then file.size else start + chunkSize)
    fileReader.readAsArrayBuffer blobSlice.call(file, start, end)
    return
  blobSlice = File::slice or File::mozSlice or File::webkitSlice
  chunkSize = 2097152
  chunks = Math.ceil(file.size / chunkSize)
  currentChunk = 0
  spark = new SparkMD5.ArrayBuffer()
  frOnload = (e) ->
    # console.log "read chunk nr", currentChunk + 1, "of", chunks
    spark.append e.target.result
    currentChunk++
    if currentChunk < chunks
      loadNext()
    else
      # console.log "finished loading"
      hash = spark.end()
      # console.info "computed hash", hash
      cb hash
    return

  frOnerror = ->
    console.warn "oops, something went wrong."
    cb null, "oops, something went wrong."
    return

  loadNext()
  return
