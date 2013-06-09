# Class: koji::params
#
# This class manages Koji parameters
#
# Parameters:
# - The $user that Koji runs as
# - The $group that Koji runs as
# - The $auth that Koji uses
# - The $hub that Koji 

#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class koji::params {

    $auth           = 'ssl'
    $realm          = ''

    #certs

}
