import csv
import math
import sys

def degToRad(angle):
    return angle*math.pi/180.0

def haversine(lat2, lon2, lat1, lon1):
    r = 3958.756  # radius of earth in mi
    temp = (math.sin((lat2-lat1)/2)*math.sin((lat2-lat1)/2)) + math.cos(lat1)*math.cos(lat2)*math.sin((lon2-lon1)/2)*math.sin((lon2-lon1)/2)
    return 2*r*math.asin(math.sqrt(temp))

def main():
    if len(sys.argv) != 2:
        raise Exception("Error, one parameter required--csv file name.")
    with open (sys.argv[1], 'rb') as csvfile:
        reader = csv.reader(csvfile, delimiter=",")
        header = reader.next()
        latIndex = header.index("Lat")
        lonIndex = header.index("Lon")
        prevPoint = reader.next()
        distance = 0
        for row in reader:
            latPrev = degToRad(float(prevPoint[latIndex]))
            lonPrev = degToRad(float(prevPoint[lonIndex]))
            lat = degToRad(float(row[latIndex]))
            lon = degToRad(float(row[lonIndex]))
            subdist = haversine(lat, lon, latPrev, lonPrev)
            distance += subdist
            prevPoint = row
        print "distance: " + str(distance)

main()


