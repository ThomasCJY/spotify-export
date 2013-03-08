require 'htmlentities'
require 'net/http'
require_relative 'spotify-cache'

class SpotifyTrack
  attr_reader :uri

  def initialize(uri)
    @uri = uri
  end

  def album
    attributes[:album]
  end

  def artist
    attributes[:artist]
  end

  def name
    attributes[:name]
  end

  private

  def attributes
    @attributes ||= begin
      cache = SpotifyCache.where(uri: uri).first

      if cache.blank?
        get_track_attributes_from_uri
      else
        { name: cache[:name], artist: cache[:artist], album: cache[:album] } 
      end
    end
  end

  def cache_track(cache_name, cache_artist, cache_album)
    SpotifyCache.create(uri: uri,
                        name: cache_name,
                        artist: cache_artist,
                        album: cache_album)
  end

  def get_track_attributes_from_uri
    target   = URI.parse(uri)
    http     = Net::HTTP.new(target.host, target.port)
    request  = Net::HTTP::Get.new(target.request_uri)
    response = http.request(request)
    html     = response.body.force_encoding("UTF-8")

    parsed_title_tag  = html.scan(/<title>(.*?) by (.*?) on Spotify<\/title>/).flatten
    parsed_album_link = html.scan(/<a href=".*?\/album\/.*?">(.*?)<\/a>/).flatten

    entities = HTMLEntities.new

    name   =  entities.decode parsed_title_tag[0]
    artist =  entities.decode parsed_title_tag[1]
    album  =  entities.decode parsed_album_link[0]

    cache_track(name, artist, album) unless response.code == "404"

    { name: name, artist: artist, album: album } 
  end

end
