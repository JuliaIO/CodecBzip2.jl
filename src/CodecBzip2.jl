__precompile__()

module CodecBzip2

export
    Bzip2Compressor,
    Bzip2CompressorStream,
    Bzip2Decompressor,
    Bzip2DecompressorStream

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
