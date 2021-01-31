import site

NonRemoveSitePackages = '/usr/local/lib/python2.7/site-packages'

site.addsitedir(NonRemoveSitePackages)
site.USER_SITE = NonRemoveSitePackages
