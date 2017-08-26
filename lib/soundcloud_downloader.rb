require 'json'
require 'httparty'
require 'pp'

starting_url = 'https://api-v2.soundcloud.com/users/669291/tracks?representation=&limit=200'
@extra_params = 'client_id=JlZIsxg2hY5WnBgtn3jfS0UYCl0K8DOg&app_version=1503651513'
@collection = []
@downloads = []
@download_location = './'

def retrieve_collection(url)
  response = HTTParty.get(url + '&' + @extra_params)
  response_hash = JSON.parse(response.body)

  if response_hash.key?('collection') && !response_hash['collection'].empty?
    @collection.push(*response_hash['collection'])
  end

  # if response_hash.key?('next_href') && !response_hash['next_href'].nil?
  #   retrieve_collection(response_hash['next_href'])
  # end
end

def pluck_download_urls
  @collection.each do |track_hash|
    @downloads.push(track_hash.select { |k, v| ['download_url', 'title'].include?(k) })
  end
end

def write_urls_to_file
  File.open('download_urls.txt', 'w+') do |f|
    f.puts(@downloads)
  end
end

def download_files
  downloaded_files = File.file?('downloaded-files.txt') ? File.readlines('downloaded-files.txt') : []

  @downloads.each do |download|
    response = nil
    filename = download['title'] + '.mp3'

    next if downloaded_files.include?(filename)

    File.open(filename, 'w+') do |file|
      file.binmode
      response = HTTParty.get(download['download_url'] + '?' + @extra_params, stream_body: true, allow_redirects: true) do |fragment|
        print "Downloading #{filename}..."
        file.write(fragment)
      end
    end

    if response.success?
      downloaded_files.push(filename)
    end

    pp "Success: #{response.success?}"
    pp File.stat(filename).inspect
  end

  File.open('downloaded-files.txt', 'w+') do |f|
    f.puts downloaded_files
  end
end

retrieve_collection(starting_url)

pluck_download_urls

download_files

# write_urls_to_file