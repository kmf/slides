import requests

url = 'https://bloximages.newyork1.vip.townnews.com/wpsdlocal6.com/content/tncms/assets/v3/editorial/7/22/722f8401-e134-5758-9f4b-a542ed88a101/5d41b45d92106.image.jpg'
filename = "source.jpg"
res = requests.get(url)
print(res.status_code)
with open(filename, 'wb') as fh:
   fh.write(res.content)


