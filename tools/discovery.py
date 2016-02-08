import os
import shutil
import time
import re

profilelist = []
foldernum = 0

while True:
    os.makedirs('items' + str(foldernum))
    for path, dirs, files in os.walk('fotologr'):
        for filename in files:
            shutil.move(os.path.join(path, filename), os.path.join('items' + str(foldernum), filename))
    with open('items' + str(foldernum) + 'processed', 'a') as itemsfile, open('items' + str(foldernum) + 'processed_bad', 'a') as itemsfilebad:
        for filename in os.listdir('items' + str(foldernum)):
            with open(os.path.join('items' + str(foldernum), filename), 'r') as urllist:
                profileslist = urllist.read().splitlines()
                for profile in profileslist:
                    if not profile in profilelist and not re.search(r'[^0-9a-zA-Z_]', profile):
                        itemsfile.write('profile:' + profile + '\n')
                        profilelist.append(profile)
                    elif re.search(r'[^0-9a-zA-Z_]', profile) and not profile in profilelist:
                        itemsfilebad.write(profile + '\n')
                        profilelist.append(profile)
    foldernum += 1
    time.sleep(1800)