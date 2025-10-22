import requests

response = requests.get('https://api.unsplash.com/search/photos?query=laptop&per_page=1', headers={'Authorization': 'Client-ID pi9B1UytpH7poYDPk4U_0bEV71DO9FMM7YWYWqz0kew'})
print(response.status_code)
if response.status_code == 200:
    data = response.json()
    print(len(data['results']))
    if data['results']:
        print(data['results'][0]['urls']['regular'])
