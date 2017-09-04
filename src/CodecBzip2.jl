__precompile__()

module CodecBzip2

export
    Bzip2Compression,
    Bzip2CompressionStream,
    Bzip2Decompression,
    Bzip2DecompressionStream

import TranscodingStreams:
    TranscodingStreams,
    TranscodingStream,
    Memory,
    Error,
    initialize,
    finalize

include("libbz2.jl")
include("compression.jl")
include("decompression.jl")

end # module
