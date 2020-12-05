import csv
import re
import requests
import unidecode
from bs4 import BeautifulSoup

def write_region(link, name):
    page = requests.get(link)
    parser = BeautifulSoup(page.content, 'lxml')
    # we will search for "Municípios integrantes:" to find the list
    title = parser.find("p", text=re.compile('Municípios integrantes:'))
    siblings = [s for s in title.next_siblings]
    cities = siblings[3]
    data = []
    for city in cities.text.split("\r\n"):
        tmp = {}
        tmp['DRS'] = name
        tmp['city'] = unidecode.unidecode(city)
        data.append(tmp)
    # CSV
    cols = ['DRS', 'city']
    target = open(name+'.csv', 'w')
    writer = csv.DictWriter(target, fieldnames=cols)
    writer.writeheader()
    for row in data:
        writer.writerow(row)

url = 'http://www.saude.sp.gov.br/ses/institucional/departamentos-regionais-de-saude/regionais-de-saude'
page = requests.get(url)
parser = BeautifulSoup(page.content, 'lxml')
text = parser.find("p", {"style": "color: #0000ff"})
drs = text.find_all("a")
base = 'http://www.saude.sp.gov.br'
for dr in drs:
    link = base + dr.get("href")
    name = unidecode.unidecode(dr.get_text().split('-')[1].strip().upper())
    write_region(link, name)
