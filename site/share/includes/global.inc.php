<?php

require_once(dirname(__FILE__).'/config.inc.php');
require_once(dirname(__FILE__).'/db.inc.php');

switch($db['type'])
{
    case 'mysql':
        $db_link = new MySQLdb($db['host'], $db['username'], $db['password'], false, $db['database']);
    break;
    case 'postgresql':
        $db_link = new PostgreSQL($db['host'], $db['username'], $db['password'], false, $db['database']);
    break;
}
unset($db);

// Set Header and cache expiration
$offset = 60 * 60 * 24 * 2; // 2 days to expiry date.
@ob_start("ob_gzhandler");
header("Expires: " . gmdate("D, d M Y H:i:s", time() + $offset) . " GMT");                                                                 
header('Cache-Control: ');
header('Pragma: ');

foreach ($_GET as $key=>$value)
{
    $_GET[$key] = urldecode($value);
}

$raw_content = '(No content available)';
if (!empty($_GET['content']))
{
    $content = urldecode($_GET['content']);
    if (preg_match('/^https?\:/', $content))
    {
        $fp = @fopen($content,'r');
        if (is_resource($fp))
        {
            $raw_content = '';
            while(!feof($fp)) $raw_content .= fread($fp,4096); 
        }
    }
}

// just a namespace
class iBeginShare
{
    function isValidEmail($email)
    {
        $email = trim($email);
        return (bool)preg_match("/^([a-z0-9\+_\-]+)(\.[a-z0-9\+_\-]+)*@([a-z0-9\-]+\.)+[a-z]{2,6}$/ix", $email);
    }
    function quoteSmart($value)
    {
        if (is_array($value))
        {
            foreach ($value as $key => $value2):
                $value[$key] = htmlspecialchars((string) trim($value2), ENT_QUOTES, 'UTF-8');
            endforeach;
            return $value;
        }
        else
        {
            return htmlspecialchars((string) trim($value), ENT_QUOTES, 'UTF-8');
        }
    }
    function messageFilter($s){
        $s = ereg_replace("[a-zA-Z]+://([.]?[a-zA-Z0-9_/-])*", " ", $s);
        return ereg_replace("(^| |.)(www([.]?[a-zA-Z0-9_/-])*)", " ", $s);
    }
    function getIp()
    {
        if (getenv('HTTP_CLIENT_IP')) $ip = getenv('HTTP_CLIENT_IP');
        elseif (getenv('HTTP_X_FORWARDED_FOR')) $ip = getenv('HTTP_X_FORWARDED_FOR');
        elseif (getenv('HTTP_X_FORWARDED')) $ip = getenv('HTTP_X_FORWARDED');
        elseif (getenv('HTTP_FORWARDED_FOR')) $ip = getenv('HTTP_FORWARDED_FOR');
        elseif (getenv('HTTP_FORWARDED'))   $ip = getenv('HTTP_FORWARDED');
        else $ip = $_SERVER['REMOTE_ADDR'];
        return $ip;
    }
    
    /**
     * Logs an action for statistics usage.
     * @param {String} $action The action name (usually the plugin name)
     * @param {String} $link The URL which this action represents.
     * @param {String} $label The label of this log action (e.g. 'Delicious').
     */
    function logAction($action, $link, $label=null)
    {
        global $db_link;
        
        $db_link->query('INSERT INTO '.IBEGIN_SHARE_TABLE_PREFIX.'log (action, label, link, ipaddress, agent, timestamp) VALUES (%s, %s, %s, %s, %s, %d)', $action, $label, $link, ip2long(iBeginShare::getIp()), getenv('HTTP_USER_AGENT'), time());
    }
}
?>