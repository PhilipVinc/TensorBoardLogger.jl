"""
    log_image(logger, name, img, step)
Logs an image using given format information and raw data
"""
@enum ImageFormat HW WH HWC WHC CHW CWH HWN WHN NHW NWH HWCN WHCN CHWN CWHN NHWC NWHC NCHW NCWH
function log_image(logger::TBLogger, name::AbstractString, imgArray::AbstractArray, format::ImageFormat; step=nothing)
    #if data contains integer numbers, scale them to 0-255 and convert to `Float64`
    imgArray = channelview(imgArray)
    if isa(first(imgArray), Integer)
        imgArray = (imgArray./255)
    end
    imgArray = Float64.(imgArray)
    #dictionary containing functions to perform for the given format
    formatdict = Dict(
    HW => function(imgArray)
        @assert ndims(imgArray) == 2
        H, W = size(imgArray)
        reshape(imgArray, (1, H, W))
    end,
    WH => function(imgArray)
        @assert ndims(imgArray) == 2
        imgArray = transpose(imgArray)
        H, W = size(imgArray)
        reshape(imgArray, (1, H, W))
    end,
    HWC => function(imgArray)
        @assert ndims(imgArray) == 3
        permutedims(imgArray, (3, 1, 2))
    end,
    WHC => function(imgArray)
        @assert ndims(imgArray) == 3
        permutedims(imgArray, (3, 2, 1))
    end,
    CHW => function(imgArray)
        @assert ndims(imgArray) == 3
        imgArray
    end,
    CWH => function(imgArray)
        @assert ndims(imgArray) == 3
        permutedims(imgArray, (1, 3, 2))
    end,
    HWN => function(imgArray)
        @assert ndims(imgArray) == 3
        N = size(imgArray, 3)
        for n in 1:N-1
            log_image(logger, name*"/$n", imgArray[:, :, n], HW, step = step)
        end
        name = name*"/$N"
        permutedims(imgArray[:, :, N:N], (3, 1, 2))
    end,
    WHN => function(imgArray)
        @assert ndims(imgArray) == 3
        N = size(imgArray, 3)
        for n in 1:N-1
            log_image(logger, name*"/$n", imgArray[:, :, n], WH, step = step)
        end
        name = name*"/$N"
        permutedims(imgArray[:, :, N:N], (3, 2, 1))
    end,
    NHW => function(imgArray)
        @assert ndims(imgArray) == 3
        N = size(imgArray, 1)
        for n in 1:N-1
            log_image(logger, name*"/$n", imgArray[n, :, :], HW, step = step)
        end
        name = name*"/$N"
        imgArray[N:N, :, :]
    end,
    NWH => function(imgArray)
        @assert ndims(imgArray) == 3
        N = size(imgArray, 1)
        for n in 1:N-1
            log_image(logger, name*"/$n", imgArray[n, :, :], WH, step = step)
        end
        name = name*"/$N"
        permutedims(imgArray[N:N, :, :], (1, 3, 2))
    end,
    HWCN => function(imgArray)
        @assert ndims(imgArray) == 4
        N = size(imgArray, 4)
        for n in 1:N-1
            log_image(logger, name*"/$n", imgArray[:, :, :, n], HWC, step = step)
        end
        name = name*"/$N"
        permutedims(imgArray[:, :, :, N], (3, 1, 2))
    end,
    WHCN => function(imgArray)
        @assert ndims(imgArray) == 4
        N = size(imgArray, 4)
        for n in 1:N-1
            log_image(logger, name*"/$n", imgArray[:, :, :, n], WHC, step = step)
        end
        name = name*"/$N"
        permutedims(imgArray[:, :, :, N], (3, 2, 1))
    end,
    CHWN => function(imgArray)
        @assert ndims(imgArray) == 4
        N = size(imgArray, 4)
        for n in 1:N-1
            log_image(logger, name*"/$n", imgArray[:, :, :, n], CHW, step = step)
        end
        name = name*"/$N"
        imgArray[:, :, :, N]
    end,
    CWHN => function(imgArray)
        @assert ndims(imgArray) == 4
        N = size(imgArray, 4)
        for n in 1:N-1
            log_image(logger, name*"/$n", imgArray[:, :, :, n], CWH, step = step)
        end
        name = name*"/$N"
        permutedims(imgArray[:, :, :, N], (1, 3, 2))
    end,
    NHWC => function(imgArray)
        @assert ndims(imgArray) == 4
        N = size(imgArray, 1)
        for n in 1:N-1
            log_image(logger, name*"/$n", imgArray[n, :, :, :], HWC, step = step)
        end
        name = name*"/$N"
        permutedims(imgArray[N, :, :, :], (3, 1, 2))
    end,
    NWHC => function(imgArray)
        @assert ndims(imgArray) == 4
        N = size(imgArray, 1)
        for n in 1:N-1
            log_image(logger, name*"/$n", imgArray[n, :, :, :], WHC, step = step)
        end
        name = name*"/$N"
        permutedims(imgArray[N, :, :, :], (3, 2, 1))
    end,
    NCHW => function(imgArray)
        @assert ndims(imgArray) == 4
        N = size(imgArray, 1)
        for n in 1:N-1
            log_image(logger, name*"/$n", imgArray[n, :, :, :], CHW, step = step)
        end
        name = name*"/$N"
        imgArray[N, :, :, :]
    end,
    NCWH => function(imgArray)
        @assert ndims(imgArray) == 4
        N = size(imgArray, 1)
        for n in 1:N-1
            log_image(logger, name*"/$n", imgArray[n, :, :, :], CWH, step = step)
        end
        name = name*"/$N"
        permutedims(imgArray[N, :, :, :], (1, 3, 2))
    end
    )
    imgArray = formatdict[format](imgArray)
    summ = SummaryCollection()
    push!(summ.value, image_summary(name, imgArray))
    write_event(logger.file, make_event(logger, summ, step=step))
end

function image_summary(name::AbstractString, imgArray::AbstractArray{Float64, 3})
    #image is strictly an Array of type Float64 format CHW
    channelcolordict = Dict(1 => Gray, 2 => GrayA, 3 => RGB, 4 => RGBA)
    channels, height, width = size(imgArray)
    @assert channels ∈ channelcolordict.keys
    if channelcolordict[channels] == Gray
        imgArray = imgArray[1, :, :]
    end
    img = colorview(channelcolordict[channels], imgArray)
    io = IOBuffer()
    save(Stream(format"PNG", io), img)
    eis = io.data
    imgsumm = Summary_Image(height = height, width = width, colorspace = 1, encoded_image_string = eis)
    Summary_Value(tag = name, image = imgsumm)
end
