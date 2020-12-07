import csv
import datetime

# recebe data em formato iso e devolve uma data que casa com o planosp
def floor_date(iso_date):
    text_dates = [
        '03/06/20', '10/06/20', '19/06/20', '26/06/20',
        '03/07/20', '10/07/20', '17/07/20', '24/07/20',
        '31/07/20', '07/08/20', '21/08/20', '04/09/20',
        '11/09/20', '09/10/20', '30/11/20'
    ]

    dates = []
    for text_date in text_dates:
        dates.append(datetime.datetime.strptime(text_date, '%d/%m/%y'))

    date = datetime.datetime.fromisoformat(iso_date) 
    for i in range(0, len(text_dates)-1):
        if (date >= dates[i] and date < dates[i+1]):
            return text_dates[i]

# parte I: print(planosp['SAO PAULO']['03/06/20'])
csvinput = open('planosp.csv', 'r')
reader = csv.reader(csvinput)

planosp = {}
header = next(reader)
for row in reader:
    fases = {}
    for i in range(0, len(row)):
        fases[header[i]] = row[i]
    planosp[row[0]] = fases

# parte II: print(drs['CAMPINAS'])
csvinput = open('all.csv', 'r')
reader = csv.reader(csvinput)

drs = {}
header = next(reader)
for row in reader:
    drs[row[1]] = row[0]
drs['SAOPAULO'] = 'SAO PAULO'

# parte III: as datas de fato
initial = datetime.datetime.fromisoformat('2020-06-03')
ndays = 180
day = datetime.timedelta(days=1)

print("date,city,phase")
for i in range(0, ndays):
    d = initial+i*day
    for city in drs:
        print(str(d.date())+","+city+","+planosp[drs[city]][floor_date(str(d.date()))])
