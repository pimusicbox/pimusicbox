<?php

require_once(dirname(__FILE__).'/includes/global.inc.php');

//process the request. like do the mailing in 'Email' section.
switch ($_GET['action'])
{
    case 'log':
        if ($_GET['plugin'] && $_GET['link'])
        {
            iBeginShare::logAction($_GET['plugin'], $_GET['link'], $_GET['name']);
        }
        header("Location: " . $_GET['to']);
        exit;
    break;
    default:
        header("Location: ../");
        exit;
    break;
}

