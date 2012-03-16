import re

# divine the version number from thrust/version.h
version = int(re.search('THRUST_VERSION ([0-9]+)', open('thrust/version.h').read()).group(1))
major   = int(version / 100000)
minor   = int(version / 100) % 1000
subminor = version % 100

# create the zip distribution
# note that we package the CHANGELOG with the headers
installation_nodes = Install('thrust', 'CHANGELOG')
Zip('thrust-{0}.{1}.{2}.zip'.format(major,minor,subminor), 'thrust')

# create the examples zip
Zip('examples-{0}.{1}.zip'.format(major,minor), 'examples')

