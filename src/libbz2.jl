# The libbz2 Interfaces
# =====================

const WIN32 = Sys.iswindows() && Sys.WORD_SIZE == 32

mutable struct BZStream
    next_in::Ptr{UInt8}
    avail_in::Cint
    total_in_lo32::Cint
    total_in_hi32::Cint

    next_out::Ptr{UInt8}
    avail_out::Cint
    total_out_lo32::Cint
    total_out_hi32::Cint

    state::Ptr{Cvoid}

    bzalloc::Ptr{Cvoid}
    bzfree::Ptr{Cvoid}
    opaque::Ptr{Cvoid}
end

function BZStream()
    return BZStream(
        C_NULL, 0, 0, 0,
        C_NULL, 0, 0, 0,
        C_NULL,
        C_NULL, C_NULL, C_NULL)
end

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


# Compressor
# ----------

function compress_init!(stream::BZStream,
                        blocksize100k::Integer,
                        verbosity::Integer,
                        workfactor::Integer)
    if WIN32
        return ccall(
            ("BZ2_bzCompressInit@16", libbz2),
            stdcall,
            Cint,
            (Ref{BZStream}, Cint, Cint, Cint),
            stream, blocksize100k, verbosity, workfactor)
    else
        return ccall(
            (:BZ2_bzCompressInit, libbz2),
            Cint,
            (Ref{BZStream}, Cint, Cint, Cint),
            stream, blocksize100k, verbosity, workfactor)
    end
end

function compress_end!(stream::BZStream)
    if WIN32
        return ccall(
            ("BZ2_bzCompressEnd@4", libbz2),
            stdcall,
            Cint,
            (Ref{BZStream},),
            stream)
    else
        return ccall(
            (:BZ2_bzCompressEnd, libbz2),
            Cint,
            (Ref{BZStream},),
            stream)
    end
end

function compress!(stream::BZStream, action::Integer)
    if WIN32
        return ccall(
            ("BZ2_bzCompress@8", libbz2),
            stdcall,
            Cint,
            (Ref{BZStream}, Cint),
            stream, action)
    else
        return ccall(
            (:BZ2_bzCompress, libbz2),
            Cint,
            (Ref{BZStream}, Cint),
            stream, action)
    end
end


# Decompressor
# ------------

function decompress_init!(stream::BZStream, verbosity::Integer, small::Bool)
    if WIN32
        return ccall(
            ("BZ2_bzDecompressInit@12", libbz2),
            stdcall,
            Cint,
            (Ref{BZStream}, Cint, Cint),
            stream, verbosity, small)
    else
        return ccall(
            (:BZ2_bzDecompressInit, libbz2),
            Cint,
            (Ref{BZStream}, Cint, Cint),
            stream, verbosity, small)
    end
end

function decompress_end!(stream::BZStream)
    if WIN32
        return ccall(
            ("BZ2_bzDecompressEnd@4", libbz2),
            stdcall,
            Cint,
            (Ref{BZStream},),
            stream)
    else
        return ccall(
            (:BZ2_bzDecompressEnd, libbz2),
            Cint,
            (Ref{BZStream},),
            stream)
    end
end

function decompress!(stream::BZStream)
    if WIN32
        return ccall(
            ("BZ2_bzDecompress@4", libbz2),
            stdcall,
            Cint,
            (Ref{BZStream},),
            stream)
    else
        return ccall(
            (:BZ2_bzDecompress, libbz2),
            Cint,
            (Ref{BZStream},),
            stream)
    end
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
