require 'net/http'
Net::HTTP.start('68.226.77.253') { |http| 
resp = http.get('/text/1DegGFS/GFS_tncc.txt')
open('GFS_tncc.txt', 'wb') { |file|
file.write(resp.body)
}
}


