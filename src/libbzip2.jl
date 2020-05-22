# The libbzip2 Interfaces
# =====================

const WIN32 = Sys.iswindows() && Sys.WORD_SIZE == 32

mutable struct BZStream
    next_in::Ptr{Cchar}
    avail_in::Cuint
    total_in_lo32::Cuint
    total_in_hi32::Cuint

    next_out::Ptr{Cchar}
    avail_out::Cuint
    total_out_lo32::Cuint
    total_out_hi32::Cuint

    state::Ptr{Cvoid}

    bzalloc::Ptr{Cvoid}
    bzfree::Ptr{Cvoid}
    opaque::Ptr{Cvoid}
end

bzalloc(::Ptr{Cvoid}, m::Cint, n::Cint) = ccall(:jl_malloc, Ptr{Cvoid}, (Cint,), m*n)
bzfree(::Ptr{Cvoid}, p::Ptr{Cvoid}) = ccall(:jl_free, Cvoid, (Ptr{Cvoid},), p)

function BZStream()
    return BZStream(
        C_NULL, 0, 0, 0,
        C_NULL, 0, 0, 0,
        C_NULL,
        @cfunction(bzalloc, Ptr{Cvoid}, (Ptr{Cvoid}, Cint, Cint)),
        @cfunction(bzfree, Cvoid, (Ptr{Cvoid}, Ptr{Cvoid})),
        C_NULL,
    )
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
            ("BZ2_bzCompressInit@16", libbzip2),
            stdcall,
            Cint,
            (Ref{BZStream}, Cint, Cint, Cint),
            stream, blocksize100k, verbosity, workfactor)
    else
        return ccall(
            (:BZ2_bzCompressInit, libbzip2),
            Cint,
            (Ref{BZStream}, Cint, Cint, Cint),
            stream, blocksize100k, verbosity, workfactor)
    end
end

function compress_end!(stream::BZStream)
    if WIN32
        return ccall(
            ("BZ2_bzCompressEnd@4", libbzip2),
            stdcall,
            Cint,
            (Ref{BZStream},),
            stream)
    else
        return ccall(
            (:BZ2_bzCompressEnd, libbzip2),
            Cint,
            (Ref{BZStream},),
            stream)
    end
end

function compress!(stream::BZStream, action::Integer)
    if WIN32
        return ccall(
            ("BZ2_bzCompress@8", libbzip2),
            stdcall,
            Cint,
            (Ref{BZStream}, Cint),
            stream, action)
    else
        return ccall(
            (:BZ2_bzCompress, libbzip2),
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
            ("BZ2_bzDecompressInit@12", libbzip2),
            stdcall,
            Cint,
            (Ref{BZStream}, Cint, Cint),
            stream, verbosity, small)
    else
        return ccall(
            (:BZ2_bzDecompressInit, libbzip2),
            Cint,
            (Ref{BZStream}, Cint, Cint),
            stream, verbosity, small)
    end
end

function decompress_end!(stream::BZStream)
    if WIN32
        return ccall(
            ("BZ2_bzDecompressEnd@4", libbzip2),
            stdcall,
            Cint,
            (Ref{BZStream},),
            stream)
    else
        return ccall(
            (:BZ2_bzDecompressEnd, libbzip2),
            Cint,
            (Ref{BZStream},),
            stream)
    end
end

function decompress!(stream::BZStream)
    if WIN32
        return ccall(
            ("BZ2_bzDecompress@4", libbzip2),
            stdcall,
            Cint,
            (Ref{BZStream},),
            stream)
    else
        return ccall(
            (:BZ2_bzDecompress, libbzip2),
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
