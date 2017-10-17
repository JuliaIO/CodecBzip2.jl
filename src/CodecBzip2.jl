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

# Deprecations
@deprecate Bzip2Compression         Bzip2Decompressor
@deprecate Bzip2CompressionStream   Bzip2CompressorStream
@deprecate Bzip2Decompression       Bzip2Decompressor
@deprecate Bzip2DecompressionStream Bzip2DecompressorStream

end # module
