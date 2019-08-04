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
    finalize,
    splitkwargs
using Libdl

const libbz2path = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
if !isfile(libbz2path)
    error("CodecBzip2.jl is not installed properly, run Pkg.build(\"CodecBzip2\") and restart Julia.")
end
include(libbz2path)
check_deps()

include("libbz2.jl")
include("compression.jl")
include("decompression.jl")

end # module
