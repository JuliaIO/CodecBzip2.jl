# Compression Codec
# =================

struct Bzip2Compression <: TranscodingStreams.Codec
    stream::BZStream
    blocksize100k::Int
    workfactor::Int
    verbosity::Int
end

const DEFAULT_BLOCKSIZE100K = 9
const DEFAULT_WORKFACTOR = 30

"""
    Bzip2Compression(;blocksize100k=$(DEFAULT_BLOCKSIZE100K), workfactor=$(DEFAULT_WORKFACTOR), verbosity=0)

Create a bzip2 compression codec.
"""
function Bzip2Compression(;blocksize100k::Integer=8, workfactor::Integer=30, verbosity::Integer=0)
    if !(1 ≤ blocksize100k ≤ 9)
        throw(ArgumentError("blocksize100k must be within 1..9"))
    elseif !(0 ≤ workfactor ≤ 250)
        throw(ArgumentError("workfactor must be within 0..250"))
    elseif !(0 ≤ verbosity ≤ 4)
        throw(ArgumentError("verbosity must be within 0..4"))
    end
    return Bzip2Compression(BZStream(), blocksize100k, workfactor, verbosity)
end

const Bzip2CompressionStream{S} = TranscodingStream{Bzip2Compression,S}

"""
    Bzip2CompressionStream(stream::IO)

Create a bzip2 compression stream by wrapping `stream`.
"""
function Bzip2CompressionStream(stream::IO)
    return TranscodingStream(Bzip2Compression(), stream)
end


# Methods
# -------

function TranscodingStreams.initialize(codec::Bzip2Compression)
    code = compress_init!(codec.stream, codec.blocksize100k, codec.verbosity, codec.workfactor)
    if code != BZ_OK
        bzerror(codec.stream, code)
    end
    finalizer(codec.stream, free_compress!)
end

function TranscodingStreams.finalize(codec::Bzip2Compression)
    free_compress!(codec.stream)
end

function free_compress!(stream::BZStream)
    if stream.state != C_NULL
        code = compress_end!(stream)
        if code != BZ_OK
            bzerror(stream, code)
        end
    end
    return
end

function TranscodingStreams.process(codec::Bzip2Compression, input::Memory, output::Memory)
    stream = codec.stream
    stream.next_in = input.ptr
    stream.avail_in = input.size
    stream.next_out = output.ptr
    stream.avail_out = output.size
    code = compress!(stream, input.size > 0 ? BZ_RUN : BZ_FINISH)
    Δin = Int(input.size - stream.avail_in)
    Δout = Int(output.size - stream.avail_out)
    if code == BZ_RUN_OK || code == BZ_FINISH_OK
        return Δin, Δout, :ok
    elseif code == BZ_STREAM_END
        return Δin, Δout, :end
    else
        bzerror(stream, code)
    end
end
