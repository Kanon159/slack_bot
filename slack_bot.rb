# test.rb
require 'http'
require 'json'
require 'eventmachine'
require 'faye/websocket'

#Ping
#response = HTTP.post("https://slack.com/api/api.test")
#puts JSON.pretty_generate(JSON.parse(response.body))

#auth test
#response = HTTP.post("https://slack.com/api/chat.postMessage", params: {
#  token: ENV['SLACK_API_TOKEN'],
#  channel: "#テスト",
#  text: "test",
#  as_user: true})

#puts JSON.pretty_generate(JSON.parse(response.body))

# web socket url 取得
response = HTTP.post("https://slack.com/api/rtm.start",params: {
  token: ENV['SLACK_API_TOKEN']
})

rc = JSON.parse(response.body)

url = rc['url']


EM.run do
  # web socket インスタンスの立ち上げ
  ws = Faye::WebSocket::Client.new(url)

  # 接続が確立された時の処理
  ws.on :open do
    p [:open]
  end

  # RTM APIから情報を受け取った時の処理
  ws.on :message do |event|
    data = JSON.parse(event.data)
    p [:message, data]

    # bot 機能
    # 会話
    if data['text'] == 'こんにちは'
      ws.send({
        type: 'message',
        text: "こんにちは,<@#{data['user']}>さん",
        channel: data['channel']
      }.to_json)
    end   # こんにちは

    if data['text'] == 'ping'
      ws.send({
        type: 'message',
        text: "pong",
        channel: data['channel']
      }.to_json)
    end   # ping


    # おふざけ
    if data['type'] == 'user_typing' && data['channel'] == 'C539B7WJU'
      ws.send({
        type: 'message',
        text: "<@#{data['user']}>!! きさま!！入力しているなッ!!!!",
        channel: data['channel']
      }.to_json)
    end   # おふざけ


    # ユーザの入室確認
    if data['channel'] == 'C50K418NT' && data['subtype'] == 'channel_join'
      ws.send({
        type: 'message',
        text: "初めまして。<@#{data['user']}>さん。slackが初めての方は説明書をどうぞ。\nhttps://files.slack.com/files-pri/T4ZVB4Y8L-F53SJEHEF/slack__________________.pdf",
        channel: data['channel']
      }.to_json)
    elsif data['subtype'] == 'channel_join' && data['channel'] != 'C4Z7Q5B0Q'
      ws.send({
        type: 'message',
        text: "こんにちは。<@#{data['user']}>さん。ここは<##{data['channel']}>です",
        channel: data['channel']
      }.to_json)
    end   # Joinのif
  end     # event確認


  # 接続が切断した時の処理
  ws.on :close do
    p [:close, event.code]
    ws = nil
    EM.stop
  end

end # ws.on
