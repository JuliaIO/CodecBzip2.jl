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

# TODO: This method will be added in the next version of TranscodingStreams.jl.
function splitkwargs(kwargs, keys)
    hits = []
    others = []
    for kwarg in kwargs
        push!(kwarg[1] ∈ keys ? hits : others, kwarg)
    end
    return hits, others
end

if !isdefined(Base, :Cvoid)
    const Cvoid = Void
end

include("libbz2.jl")
include("compression.jl")
include("decompression.jl")

# Deprecations
@deprecate Bzip2Compression         Bzip2Compressor
@deprecate Bzip2CompressionStream   Bzip2CompressorStream
@deprecate Bzip2Decompression       Bzip2Decompressor
@deprecate Bzip2DecompressionStream Bzip2DecompressorStream

end # module
