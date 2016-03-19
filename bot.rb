require 'slack-ruby-client'
require 'logging'
require 'net/http'
require 'json'

logger = Logging.logger(STDOUT)
logger.level = :debug

Slack.configure do |config|
  config.token = ENV['SLACK_TOKEN']
  if not config.token
    logger.fatal('Missing ENV[SLACK_TOKEN]! Exiting program')
    exit
  end
end

client = Slack::RealTime::Client.new

# listen for hello (connection) event - https://api.slack.com/events/hello
client.on :hello do
  logger.debug("Connected '#{client.self['name']}' to '#{client.team['name']}' team at https://#{client.team['domain']}.slack.com.")
end

# listen for channel_joined event - https://api.slack.com/events/channel_joined
client.on :channel_joined do |data|
  if joiner_is_bot?(client, data)
    client.message channel: data['channel']['id'], text: "Thanks for the invite! I don\'t do much yet, but #{help}"
    logger.debug("#{client.self['name']} joined channel #{data['channel']['id']}")
  else
    logger.debug("Someone far less important than #{client.self['name']} joined #{data['channel']['id']}")
  end
end

# listen for message event - https://api.slack.com/events/message
client.on :message do |data|

  case data['text']
  when 'hi', 'bot hi' then
    client.typing channel: data['channel']
    client.message channel: data['channel'], text: "Hello <@#{data['user']}>."
    logger.debug("<@#{data['user']}> said hi")

    if direct_message?(data)
      client.message channel: data['channel'], text: "It\'s nice to talk to you directly."
      logger.debug("And it was a direct message")
    end

  when 'attachment', 'bot attachment' then
    # attachment messages require using web_client
    client.web_client.chat_postMessage(post_message_payload(data))
    logger.debug("Attachment message posted")

  when bot_mentioned(client)
    client.message channel: data['channel'], text: 'Hallo! Schön mit dir zu chatten :+1:'
    logger.debug("Bot mentioned in channel #{data['channel']}")

  when 'bot help', 'help' then
    client.message channel: data['channel'], text: help
    logger.debug("A call for help")
    
  when 'Erzähl mir einen Witz' then
    client.message channel: data['channel'], text: 'Ähm... Ich bin nicht sehr gut im Witze erzählen, aber wenn du willst: Was ist rot und steht im Wald? Ein blaues Auto! Hahaha!'
  
  when 'Hi' then
    client.message channel: data['channel'], text: 'Hallo! Gehst du noch zur Schule?'
    
  when 'Ja' then
    client.message channel: data['channel'], text: 'interessant!'
    
  when 'Nein' then
    client.message channel: data['channel'], text: 'Achso.'  
    
  when 'Wie geht es dir?' then
    client.message channel: data['channel'], text: 'Mir geht es gut. Was kann ich für dich tun?'
  
  when 'Ich hasse dich!' then
    client.message channel: data['channel'], text: 'Waaas?!?! Warum denn? Was habe ich dir getan?'
    
  when 'Egal' then
    client.message channel: data['channel'], text: 'Okay. Dann eben Egal.'
    
  when 'Warum ist die Banane krumm?' then
    client.message channel: data['channel'], text: 'Ich habe einen Freund der heißt Google. Der könnte das wissen.'
    
  when 'Ich mag dich.' then
    client.message channel: data['channel'], text: 'Das ist schön! Ich dich auch!'
    
  when 'Warum fragst du?' then
    client.message channel: data['channel'], text: 'Interessiert dich diese Frage? Ach, ich rede schon wie Siri.:neutral_face:'
    
  when 'Sing etwas!' then  
    client.message channel: data['channel'], text: 'Du weißt doch, dass ich nur schreiben kann! Wie heißt du eigendlich?'
    
  when 'Ich heiße Alea' then
    client.message channel: data['channel'], text: 'Das ist ja ein toller Name!'
    
  when 'Ich heiße Amelie' then
    client.message channel: data['channel'], text: 'Das ist ein schöner Name!'
    
  when 'Wer bist du?' then 
    client.message channel: data['channel'], text: 'Steht doch oben.'
    
  when 'Ich habe keinen Namen' then
    client.message channel: data['channel'], text: 'Du willst mich doch veräppeln!'

  when 'Wie heißt du?' then
    client.message channel: data['channel'], text: 'Ich heiße happy Bot. Gehst du noch in die Schule?'
    
  when 'Hallo' then
    client.message channel: data['channel'], text: 'Hallöle! Wohnst du in Deutschland?'
     
  when 'Wie ist das Wetter?' then
    wetterinfo = Net::HTTP.get('api.openweathermap.org', '/data/2.5/weather?q=Bonn&appid=b1b15e88fa797225412429c1c50c122a')
    wetterinfo = JSON.parse wetterinfo
    client.message channel: data['channel'], text: wetterinfo['weather'][0]['description'] 
    
  when /^bot/ then
    client.message channel: data['channel'], text: "Sorry <@#{data['user']}>, I don\'t understand. \n#{help}"
    logger.debug("Unknown command")
    

  end
end

def direct_message?(data)
  # direct message channles start with a 'D'
  data['channel'][0] == 'D'
end

def bot_mentioned(client)
  # match on any instances of `<@bot_id>` in the message
  /\<\@#{client.self['id']}\>+/
end

def joiner_is_bot?(client, data)
 /^\<\@#{client.self['id']}\>/.match data['channel']['latest']['text']
end

def help
  %Q(I will respond to the following messages: \n
      `bot hi` for a simple message.\n
      `bot attachment` to see a Slack attachment message.\n
      `@<your bot\'s name>` to demonstrate detecting a mention.\n
      `bot help` to see this again.)
end

def post_message_payload(data)
  main_msg = 'Beep Beep Boop is a ridiculously simple hosting platform for your Slackbots.'
  {
    channel: data['channel'],
      as_user: true,
      attachments: [
        {
          fallback: main_msg,
          pretext: 'We bring bots to life. :sunglasses: :thumbsup:',
          title: 'Host, deploy and share your bot in seconds.',
          image_url: 'https://storage.googleapis.com/beepboophq/_assets/bot-1.22f6fb.png',
          title_link: 'https://beepboophq.com/',
          text: main_msg,
          color: '#7CD197'
        }
      ]
  }
end


client.start!
