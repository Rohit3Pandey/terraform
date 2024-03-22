import requests


response = requests.get("https://api.github.com/repos/kubernetes/kubernetes/pulls")
output = response.json()
for i in range(len(output)):
    print(output[i]["user"]["login"])