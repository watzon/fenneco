# require "http/client"
# require "mime/multipart"

# class Fennec < Proton::Client
#   @[Command(".vs")]
#   def virus_scan_command(ctx)
#     if !ENV["VIRUS_TOTAL_API_KEY"]?
#       return edit_message(ctx.message, "`No virus total API key. Please provide one.`")
#     end

#     endpoint = "https://www.virustotal.com/api/v3/"
#     headers = HTTP::Headers{
#       "x-apikey" => ENV["VIRUS_TOTAL_API_KEY"]
#     }

#     if reply_message = ctx.message.reply_message
#       content = reply_message.content!
#       if content.is_a?(TL::MessageDocument)
#         document = content.document!
#         file = document.document!

#         if (localfile = file.local!) && !(localfile.path!.empty?)
#           filepath = localfile.path!
#         else
#           file = TL.download_file(file.id!, 1, 0, 0, false)
#           filepath = file.local!.path!
#         end

#         io = File.open(filepath)
#         filename = File.basename(filepath)
#         form = MIME::Multipart.build do |builder|
#           builder.body_part(
#             HTTP::Headers{"Content-Disposition" => "form-data; name=\"file\"; filename=\"#{filename}\""},
#             io
#           )
#         end

#         puts form[0..1000]

#         response = HTTP::Client.post(File.join(endpoint, "files"), headers, form: form.to_s)
#         pp response
#       else
#         return edit_message(ctx.message, "`Virus scanning only works with documents for now.`")
#       end
#     else
#       return edit_message(ctx.message, "`Please reply to a message with the file you want to scan.`")
#     end
#   end
# end
