require 'date'
require 'json'

TEMP_WHITESPACE = '___'

# GFS data hash
gfs = {}

def parse_station_id_lat_lon(line)
  #  Station ID: TNCC Lat:   12.19 Long:   68.96  
  match = line.match /Station ID:\s*(\w*) Lat:\s*(\d*\.?\d*)\s*Long:\s*(\d*\.?\d*)/
  [match[1], match[2].to_f, match[3].to_f]
end



line_num=0
quantities = []
File.open('tst_TNCC.txt').each do |line|
  case line_num
  when 0
     # station_id, lat, lon
    gfs[:station_id], gfs[:lat], gfs[:lon] = parse_station_id_lat_lon(line)
  
  end
  line_num += 1
end

puts gfs.to_json