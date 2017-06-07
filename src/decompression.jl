# Decompression Codec
# ===================

struct Bzip2Decompression <: TranscodingStreams.Codec
    stream::BZStream
    small::Bool
    verbosity::Int
end

"""
    Bzip2Decompression(;small=false, verbosity=0)

Create a bzip2 decompression codec.
"""
function Bzip2Decompression(;small::Bool=false, verbosity::Integer=0)
    if !(0 ≤ verbosity ≤ 4)
        throw(ArgumentError("verbosity must be within 0..4"))
    end
    return Bzip2Decompression(BZStream(), small, verbosity)
end

const Bzip2DecompressionStream{S} = TranscodingStream{Bzip2Decompression,S}

"""
    Bzip2DecompressionStream(stream::IO)

Create a bzip2 decompression stream by wrapping `stream`.
"""
function Bzip2DecompressionStream(stream::IO)
    return TranscodingStream(Bzip2Decompression(), stream)
end


# Methods
# -------

function TranscodingStreams.initialize(codec::Bzip2Decompression)
    code = decompress_init!(codec.stream, codec.verbosity, codec.small)
    if code != BZ_OK
        bzerror(codec.stream, code)
    end
    finalizer(codec.stream, free_decompress!)
end

function TranscodingStreams.finalize(codec::Bzip2Decompression)
    free_decompress!(codec.stream)
end

function free_decompress!(stream::BZStream)
    if stream.state != C_NULL
        code = decompress_end!(stream)
        if code != BZ_OK
            bzerror(stream, code)
        end
    end
    return
end

function TranscodingStreams.process(codec::Bzip2Decompression, input::Memory, output::Memory)
    stream = codec.stream
    stream.next_in = input.ptr
    stream.avail_in = input.size
    stream.next_out = output.ptr
    stream.avail_out = output.size
    code = decompress!(stream)
    Δin = Int(input.size - stream.avail_in)
    Δout = Int(output.size - stream.avail_out)
    if code == BZ_OK
        return Δin, Δout, :ok
    elseif code == BZ_STREAM_END
        return Δin, Δout, :end
    else
        bzerror(stream, code)
    end
end
