# The libbz2 Interfaces
# =====================

mutable struct BZStream
    next_in::Ptr{UInt8}
    avail_in::Cint
    total_in_lo32::Cint
    total_in_hi32::Cint

    next_out::Ptr{UInt8}
    avail_out::Cint
    total_out_lo32::Cint
    total_out_hi32::Cint

    state::Ptr{Void}

    bzalloc::Ptr{Void}
    bzfree::Ptr{Void}
    opaque::Ptr{Void}
end

function BZStream()
    return BZStream(
        C_NULL, 0, 0, 0,
        C_NULL, 0, 0, 0,
        C_NULL,
        C_NULL, C_NULL, C_NULL)
end

const libbz2 = "libbz2"

# Action code
const BZ_RUN              = Cint(0)
const BZ_FLUSH            = Cint(1)
const BZ_FINISH           = Cint(2)

# Return code
const BZ_OK               = Cint( 0)
const BZ_RUN_OK           = Cint( 1)
const BZ_FLUSH_OK         = Cint( 2)
const BZ_FINISH_OK        = Cint( 3)
const BZ_STREAM_END       = Cint( 4)
const BZ_SEQUENCE_ERROR   = Cint(-1)
const BZ_PARAM_ERROR      = Cint(-2)
const BZ_MEM_ERROR        = Cint(-3)
const BZ_DATA_ERROR       = Cint(-4)
const BZ_DATA_ERROR_MAGIC = Cint(-5)
const BZ_IO_ERROR         = Cint(-6)
const BZ_UNEXPECTED_EOF   = Cint(-7)
const BZ_OUTBUFF_FULL     = Cint(-8)
const BZ_CONFIG_ERROR     = Cint(-9)


# Compression
# -----------

function compress_init!(stream::BZStream,
                        blocksize100k::Integer,
                        verbosity::Integer,
                        workfactor::Integer)
    return ccall(
        (:BZ2_bzCompressInit, libbz2),
        Cint,
        (Ref{BZStream}, Cint, Cint, Cint),
        stream, blocksize100k, verbosity, workfactor)
end

function compress_end!(stream::BZStream)
    return ccall(
        (:BZ2_bzCompressEnd, libbz2),
        Cint,
        (Ref{BZStream},),
        stream)
end

function compress!(stream::BZStream, action::Integer)
    return ccall(
        (:BZ2_bzCompress, libbz2),
        Cint,
        (Ref{BZStream}, Cint),
        stream, action)
end


# Decompression
# -------------

function decompress_init!(stream::BZStream, verbosity::Integer, small::Bool)
    return ccall(
        (:BZ2_bzDecompressInit, libbz2),
        Cint,
        (Ref{BZStream}, Cint, Cint),
        stream, verbosity, small)
end

function decompress_end!(stream::BZStream)
    return ccall(
        (:BZ2_bzDecompressEnd, libbz2),
        Cint,
        (Ref{BZStream},),
        stream)
end

function decompress!(stream::BZStream)
    return ccall(
        (:BZ2_bzDecompress, libbz2),
        Cint,
        (Ref{BZStream},),
        stream)
end


# Error
# -----

struct BZ2Error <: Exception
    code::Cint
end

function bzerror(stream::BZStream, code::Cint)
    @assert code < 0
    throw(BZ2Error(code))
end
