<?php
/**
 * DokuWiki Plugin sandstorm (Auth Component)
 *
 * @license GPL 2 http://www.gnu.org/licenses/gpl-2.0.html
 * @author  Nolan Darilek <nolan@thewordnerd.info>
 */

// must be run within Dokuwiki
if(!defined('DOKU_INC')) die();

class auth_plugin_sandstorm extends DokuWiki_Auth_Plugin {


    /**
     * Constructor.
     */
    public function __construct() {
        parent::__construct(); // for compatibility

        // FIXME set capabilities accordingly
        //$this->cando['addUser']     = false; // can Users be created?
        //$this->cando['delUser']     = false; // can Users be deleted?
        //$this->cando['modLogin']    = false; // can login names be changed?
        //$this->cando['modPass']     = false; // can passwords be changed?
        //$this->cando['modName']     = false; // can real names be changed?
        //$this->cando['modMail']     = false; // can emails be changed?
        //$this->cando['modGroups']   = false; // can groups be changed?
        //$this->cando['getUsers']    = false; // can a (filtered) list of users be retrieved?
        //$this->cando['getUserCount']= false; // can the number of users be retrieved?
        //$this->cando['getGroups']   = false; // can a list of available groups be retrieved?
        $this->cando['external']    = true; // does the module do external auth checking?
        $this->cando['logout']      = false; // can the user logout again? (eg. not possible with HTTP auth)

        // FIXME intialize your auth system and set success to true, if successful
        $this->success = true;
    }

    /**
     * Do all authentication [ OPTIONAL ]
     *
     * @param   string  $user    Username
     * @param   string  $pass    Cleartext Password
     * @param   bool    $sticky  Cookie should not expire
     * @return  bool             true on successful auth
     */
    public function trustExternal($user, $pass, $sticky = true) {
        global $USERINFO;
        global $conf;
        $sticky = true;
        $USERINFO['name'] = rawurldecode($_SERVER['HTTP_X_SANDSTORM_USERNAME']);
        $USERINFO['mail'] = 'user@example.com';
        $USERINFO['grps'] = str_getcsv($_SERVER['HTTP_X_SANDSTORM_PERMISSIONS']);
        $_SERVER['REMOTE_USER'] = $_SERVER['HTTP_X_SANDSTORM_USER_ID'];
        $_SESSION[DOKU_COOKIE]['auth']['user'] = $USERINFO['name'];
        $_SESSION[DOKU_COOKIE]['auth']['pass'] = $pass;
        $_SESSION[DOKU_COOKIE]['auth']['info'] = $USERINFO;
        return true;
    }

}

// vim:ts=4:sw=4:et:
