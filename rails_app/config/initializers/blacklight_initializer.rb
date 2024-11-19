# A secret token used to encrypt user_id's in the Bookmarks#export callback URL
# functionality, for example in Refworks export of Bookmarks. In Rails 4, Blacklight
# will use the application's secret key base instead.
#

# Blacklight.secret_key = '2cd2603b3abf9c54d8e7d6988ffd88778d7e1658826eeec9534de1615258fc4d4a1847981e38cc6828bd4c1e0fe1d2572311d311455c5792fa65485eb476c485'

Blacklight.secret_key = ENV['SDBMSS_BLACKLIGHT_SECRET_KEY']
