class LinebotsController < ApplicationController
  require 'line/bot'
  protect_from_forgery except:[:callback]

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body,signature)
      return head :bad_request
    end
    events = client.parse_events_from(body)
    events.each do |event|
      case event
        when Line::Bot::Event::Message
        case event.type
          when Line::Bot::Event::MessageType::Text
            input = event.message['text']
            message = get_wp_article(input)
            client.reply_message(event['replyToken'],message)
        end
      end
    end
    head :ok
  end

  private
  def client
    @client ||= Line::Bot::Client.new do |config|
      config.channel_secret = ENV['LINE_BOT_CHANNEL_SECRET']
      config.channel_token = ENV['LINE_BOT_CHANNEL_TOKEN']
    end
  end

    def get_wp_article(type)
      case type
        when "HTML"
          uri = URI.parse("https://taketon-blog.com/kazugramming/wp-json/wp/v2/posts?per_page=3&categories=3&meta_key=views")
        when "CSS"
          uri = URI.parse("https://taketon-blog.com/kazugramming/wp-json/wp/v2/posts?per_page=3&categories=4&meta_key=views")
        when "Ruby"
          uri = URI.parse("https://taketon-blog.com/kazugramming/wp-json/wp/v2/posts?per_page=3&categories=5&meta_key=views")
        when "JavaScript"
          uri = URI.parse("https://taketon-blog.com/kazugramming/wp-json/wp/v2/posts?per_page=3&categories=6&meta_key=views")
      else
        return
      end
        http = Net::HTTP.new(uri.host,uri.port)
        http.use_ssl = true
        req = Net::HTTP::Get.new(uri)
        res = http.request(req)
        results = JSON.parse(res.body)
        make_reply_content(results)
    end

    def make_reply_content(items)
      {
        "type": "template",
        "altText": "this is a carousel template",
        "template": {
            "type": "carousel",
            "columns": [
              make_part(items[0]),
              meke_part(items[1]),
              meke_part(items[2])
            ],
            "imageAspectRatio": "rectangle",
            "imageSize": "cover"
        }
      }
    end

    def make_part(item)
      {
        "thumbnailImageUrl": item['thumbnail_url']['medium']['url'],
        "imageBackgroundColor": "#FFFFFF",
        "title": item['title']['rendered'],
        # "text": "description",
        # "defaultAction": {
        #     "type": "uri",
        #     "label": "View detail",
        #     "uri": "http://example.com/page/123"
        # },
        "actions": [
            {
                "type": "uri",
                "label": "この記事を読む",
                "uri": item['guid']['rendered']
            }
        ]
      }
    end
end
