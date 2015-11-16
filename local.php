<?php
/**
 * This is an example of how a local.php could look like.
 * Simply copy the options you want to change from dokuwiki.php
 * to this file and change them.
 *
 * When using the installer, a correct local.php file be generated for
 * you automatically.
 */

$conf['useacl']      = 1;                //Use Access Control Lists to restrict access?
$conf['autopasswd']  = 0;                //autogenerate passwords and email them to user
$conf['authtype']    = 'sandstorm';      //which authentication backend should be used
$conf['superuser']   = '@admin';    //The admin can be user or @group or comma separated list user1,@group1,user2
$conf['manager']     = '@manager';    //The manager can be user or @group or comma separated list user1,@group1,user2
$conf['profileconfirm'] = 0;             //Require current password to confirm changes to user profile
$conf['disableactions']='login';