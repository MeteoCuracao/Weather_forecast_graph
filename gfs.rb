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

def parse_date(line)
  # GFS Model Run: 12Z  6MAR 2013
  match = line.match /Run: (\d*Z)\s*(\d*)(\w*)\s*(\d*)/
  Date.parse '%s %s %s %s:00:00' % [match[2], match[3], match[4], match[1]]
end

def parse_quantities(line)
  # HR Valid     2m Tmp 2m Dpt 10m Dir 10m Spd TPrcp CPrcp 1000-500 500mb 850mb 500mb  MSLP  TCC PRS WX  Low      Middle     High     Max    Min  Sfc
  line = line.gsub /(\d+m) (\w+)/, '\1%s\2' % TEMP_WHITESPACE
  line = line.gsub /PRS WX/, "PRS#{TEMP_WHITESPACE}WX"
  line.strip.split(/\s+/).map! { |quantity| quantity.sub(TEMP_WHITESPACE, ' ') }
end

def parse_units(line)
  #    Deg F  Deg F   deg      kt    in.   in.     Thk    GPH   Tmp   Tmp    mb    %  TEXT   Clouds    Clouds    Clouds    Tmp    Tmp  Vis
  [nil,nil] + line.strip.split(/\s{2,}/)
end


def parse_values(line)
  # Length of fields in GFS_TNCC.txt
  # e.g. first field (HR) is 4 characters long, second field (Valid date)
  # is 10 characters long. 
  # TODO: read lenghts from file itself!
  fields = [4,10,7,7,8,8,6,6,9,6,6,6,7,4,7,10,7,12,5,7,5]
  field_pattern = "A#{fields.join('A')}"
  line.unpack(field_pattern).map! { |value| value.strip }
end

def parse_value(value, index)
#  HR Valid     2m Tmp 2m Dpt 10m Dir 10m Spd TPrcp CPrcp 1000-500 500mb 850mb 500mb  MSLP  TCC PRS WX  Low      Middle     High     Max    Min  Sfc
#   0 03/06 12Z   80     73      92      19    0.01  0.00    576    587   17.2  -5.3 1013.6   0          CLR       CLR       CLR    ****   **** 16.8
  case index
  when 1
    # date field
    value
  when 0, 2, 3, 4, 5, 8, 9, 13, 18, 19
    # integer fields
    value.to_i 
  when 6, 7, 10, 11, 12, 20
    # float fields
    value.to_f
  else
    # text fields
    value
  end
end


line_num=0
quantities = []
File.open('GFS_TNCC.txt').each do |line|
  case line_num
  when 0
    # station_id, lat, lon
    gfs[:station_id], gfs[:lat], gfs[:lon] = parse_station_id_lat_lon(line)
  when 1
    # date
    gfs[:date] = parse_date(line)
  when 2
    # quantities
    quantities = parse_quantities(line)
    #{'2m' => {:values => {}}}
    gfs[:data] = quantities.reduce({}) do |accu, quantity|
      accu[quantity] ||= {}
      accu[quantity] = {:values => []}
      accu
    end
  when 3
    # units
    parse_units(line).each_with_index {|unit, index|
      gfs[:data][quantities[index]][:unit] = unit if not unit.nil?
    }
  else
    # values
    values = parse_values(line)
    values.each_with_index {|value, index|
      gfs[:data][quantities[index]][:values] << parse_value(value, index)
    }


    #puts row.inspect
    #  ... #use row[0] etc for each field

  end
  line_num += 1
end

puts gfs.to_json