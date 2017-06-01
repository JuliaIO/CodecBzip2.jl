# Compression Codec
# =================

struct Bzip2Compression <: TranscodingStreams.Codec
    stream::BZStream
end

function Bzip2Compression(;blocksize100k::Integer=8, workfactor::Integer=30, verbosity::Integer=0)
    if !(1 ≤ blocksize100k ≤ 9)
        throw(ArgumentError("blocksize100k must be within 1..9"))
    elseif !(0 ≤ workfactor ≤ 250)
        throw(ArgumentError("workfactor must be within 0..250"))
    elseif !(0 ≤ verbosity ≤ 4)
        throw(ArgumentError("verbosity must be within 0..4"))
    end
    stream = BZStream()
    code = compress_init!(stream, blocksize100k, verbosity, workfactor)
    if code != BZ_OK
        bzerror(stream, code)
    end
    return Bzip2Compression(stream)
end

const Bzip2CompressionStream{S} = TranscodingStream{Bzip2Compression,S} where S<:IO

function Bzip2CompressionStream(stream::IO)
    return TranscodingStream(Bzip2Compression(), stream)
end


# Methods
# -------

function TranscodingStreams.process(codec::Bzip2Compression, input::Memory, output::Memory)
    stream = codec.stream
    stream.next_in = input.ptr
    stream.avail_in = input.size
    stream.next_out = output.ptr
    stream.avail_out = output.size
    code = compress!(stream, input.size > 0 ? BZ_RUN : BZ_FINISH)
    Δin = Int(input.size - stream.avail_in)
    Δout = Int(output.size - stream.avail_out)
    if code == BZ_RUN_OK
        return Δin, Δout, :ok
    elseif code == BZ_FINISH_OK
        return Δin, Δout, :ok
    elseif code == BZ_STREAM_END
        return Δin, Δout, :end
    else
        bzerror(stream, code)
    end
end

function TranscodingStreams.finalize(codec::Bzip2Compression)
    code = compress_end!(codec.stream)
    if code != BZ_OK
        bzerror(stream, code)
    end
    return
end
