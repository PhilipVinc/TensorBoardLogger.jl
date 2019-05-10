"""
    log_image(logger, name, img, step)
Logs an image
"""
function log_image(logger::TBLogger, name::AbstractString, img::Array; step=nothing)
    summ = SummaryCollection()
    push!(summ.value, image_summary(name, img))
    write_event(logger.file, make_event(logger, summ, step=step))
end

function image_summary(name::AbstractString, img::Array)
    #assuming input is in HWC #C is currently = 1
    #assuming input is of type Float64
    #obtain height, width channel of image
    height, width, channel = size(img)
    #Encode image to string
    Img = colorview(Gray, img)
    #TODO Poor implementation, MUST not save as file
    #use something like PipeBuffer 
    save("temp.png", Img)
    ImgFile = open("temp.png")
    Img = read(ImgFile, String)
    close(ImgFile)
    rm("temp.png")
    eis = Vector{UInt8}(Img)
    imgsumm = Summary_Image(height = height, width = width, colorspace = channel, encoded_image_string = eis)
    Summary_Value(tag = name, image = imgsumm)
end


"""
import TensorBoardLogger
using .TensorBoardLogger
lgr = TBLogger("/home/shashi/run")
img = rand(16, 16, 1)
log_value(lgr, "testval", 16, step = 0)
log_image(lgr, "testimage", img, step = 0)
"""
